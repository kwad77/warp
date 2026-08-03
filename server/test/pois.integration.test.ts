// SPEC §7 — POI discovery/creation + photo presign/complete, against real PostGIS.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { SPEC_CONSTANTS } from '../src/constants.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import type { ModerationProvider, ModerationVerdict } from '../src/moderation/provider.js';
import { devTextModerationProvider } from '../src/moderation/text_provider.js';
import type { Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

/** Approximate meters → degrees latitude offset (good enough at these small distances). */
function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

function offsetLngMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat, lng: ll.lng + meters / (111_320 * Math.cos((ll.lat * Math.PI) / 180)) };
}

// Distinct from checkins.integration.test's Lisbon fixture, and salted per run — on BOTH
// axes, not just latitude — so this suite's dedupe-proximity ("no OTHER poi nearby")
// assertions never collide with rows a previous run left behind in this shared,
// never-reset dev/test database. A latitude-only salt collapses the random space to a
// single ~400km line at a fixed longitude, which saturates against its own history after
// enough accumulated runs (reproduced: the "200m away does NOT trigger dedupe" case failed
// against a real collision when run alongside the rest of the suite).
const BASE_LL = { lat: 39.5, lng: -8.0 };
const POI_LL = offsetLngMeters(
  offsetLatMeters(BASE_LL, Math.floor(Math.random() * 400_000)),
  Math.floor(Math.random() * 400_000),
);

/** Configurable fake so photo tests can drive presign/head without a real R2 bucket. */
class FakeStorage implements Storage {
  headResult: { bytes: number; contentType: string } | null = {
    bytes: 500_000,
    contentType: 'image/jpeg',
  };
  // null (default): computeAndStorePhotoMetrics degrades to skipping metrics, same as
  // this suite's pre-pHash behavior — these tests aren't about metrics/dimension checks.
  getResult: Uint8Array | null = null;

  async presignPut(storageKey: string, _contentType: string) {
    return {
      uploadUrl: `https://fake-r2.example/${storageKey}`,
      storageKey,
      maxBytes: SPEC_CONSTANTS.photos.UPLOAD_MAX_BYTES,
      expiresInS: 600,
    };
  }

  async head(_storageKey: string) {
    return this.headResult;
  }

  async get(_storageKey: string) {
    return this.getResult;
  }
}

/** Configurable fake so moderation wiring is testable without a real detector. */
class FakeModerationProvider implements ModerationProvider {
  nextVerdict: ModerationVerdict = { outcome: 'approved' };
  calls: { photoId: string; storageKey: string }[] = [];

  async moderate(input: { photoId: string; storageKey: string }) {
    this.calls.push(input);
    return this.nextVerdict;
  }
}

describe.runIf(!!url)('POI + photo endpoints (SPEC §7)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;
  let moderation: FakeModerationProvider;
  let storage: FakeStorage;
  let auth: { headers: { authorization: string }; userId: string };

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `poi-${randomUUID().slice(0, 12)}@example.com`;
    const { requestEmailCode } = await import('../src/auth/service.js');
    let code = '';
    await requestEmailCode(
      handle.db,
      {
        sendLoginCode: async (_e, c) => {
          code = c;
        },
      },
      email,
      new Date(),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code },
    });
    expect(res.statusCode).toBe(200);
    return {
      headers: { authorization: `Bearer ${res.json().accessToken}` },
      userId: res.json().user.id,
    };
  }

  async function makeDevice(headers: { authorization: string }): Promise<string> {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/devices',
      headers,
      payload: { platform: 'android', model: 'Pixel 8' },
    });
    expect(res.statusCode).toBe(201);
    return res.json().deviceId;
  }

  async function makePoi(
    creatorId: string,
    ll = POI_LL,
    category = 'landmark',
    radiusM = 75,
    status = 'active',
  ): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${id}, ${creatorId}, ${'Miradouro de Teste'}, ${category},
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll)).toString()}, ${radiusM}, ${status})`;
    return id;
  }

  function createPayload(overrides: Record<string, unknown> = {}) {
    return {
      title: 'A Very Nice Place',
      category: 'landmark',
      location: POI_LL,
      gpsFix: { ...POI_LL, accuracyM: 10, capturedAt: new Date().toISOString() },
      ...overrides,
    };
  }

  beforeAll(async () => {
    await migrate(url as string, () => {});
    handle = createDb(url as string);
    storage = new FakeStorage();
    moderation = new FakeModerationProvider();
    app = buildApp({
      config: loadConfig({
        JWT_SECRET: 'test-secret-that-is-at-least-32-chars!!',
        NODE_ENV: 'test',
        DATABASE_URL: url,
      }),
      dbHandle: handle,
      storage,
      moderation,
      textModeration: devTextModerationProvider(),
      oidcVerifiers: { apple: null, google: null },
    });
    auth = await makeUser();
    await makeDevice(auth.headers);
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });
  beforeEach(() => {
    moderation.nextVerdict = { outcome: 'approved' };
    moderation.calls = [];
  });

  describe('POST /pois', () => {
    it('happy path: 201, radius from category, h3_r9 set', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: auth.headers,
        payload: createPayload({ category: 'viewpoint' }),
      });
      expect(res.statusCode).toBe(201);
      const { poi } = res.json();
      expect(poi.checkinRadiusM).toBe(SPEC_CONSTANTS.checkinRadiusM.viewpoint);
      expect(poi.category).toBe('viewpoint');
      expect(poi.creator.id).toBe(auth.userId);

      const row = await handle.pg`SELECT h3_r9 FROM pois WHERE id = ${poi.id}`;
      expect(row[0]?.h3_r9).toBe(h3ToBigint(dedupeCell(POI_LL)).toString());
    });

    it('title with Japanese characters counts Unicode code points, not UTF-16 units', async () => {
      // 3 kanji code points — well under the UTF-16 unit count some of these characters use.
      const jpLocation = offsetLatMeters(POI_LL, 1000);
      const res = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: auth.headers,
        payload: createPayload({
          title: '東京都',
          location: jpLocation,
          gpsFix: { ...jpLocation, accuracyM: 10, capturedAt: new Date().toISOString() },
        }),
      });
      expect(res.statusCode).toBe(201);
      expect(res.json().poi.title).toBe('東京都');
    });

    it('title under 3 code points → 400 request/invalid', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: auth.headers,
        payload: createPayload({ title: 'ab' }),
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe('request/invalid');
    });

    it('pin adjust violation: gpsFix far from location → 422 poi/outside_pin_adjust', async () => {
      const far = offsetLatMeters(POI_LL, 500);
      const res = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: auth.headers,
        payload: createPayload({
          location: offsetLatMeters(POI_LL, 2000),
          gpsFix: { ...far, accuracyM: 10, capturedAt: new Date().toISOString() },
        }),
      });
      expect(res.statusCode).toBe(422);
      expect(res.json().error.code).toBe('poi/outside_pin_adjust');
    });

    it('dedupe: a POI 30m away is offered as a candidate; force:true creates anyway', async () => {
      const u = await makeUser();
      const base = offsetLatMeters(POI_LL, 5000);
      const existing = await makePoi(u.userId, base);

      const nearby = offsetLatMeters(base, 20); // well within DEDUPE_RADIUS_M (50m)
      const dedupeRes = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: u.headers,
        payload: createPayload({
          location: nearby,
          gpsFix: { ...nearby, accuracyM: 10, capturedAt: new Date().toISOString() },
        }),
      });
      expect(dedupeRes.statusCode).toBe(200);
      const candidateIds = dedupeRes.json().dedupeCandidates.map((p: { id: string }) => p.id);
      expect(candidateIds).toContain(existing);

      const forced = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: u.headers,
        payload: createPayload({
          location: nearby,
          gpsFix: { ...nearby, accuracyM: 10, capturedAt: new Date().toISOString() },
          force: true,
        }),
      });
      expect(forced.statusCode).toBe(201);
    });

    it('a POI 200m away does NOT trigger dedupe', async () => {
      const u = await makeUser();
      const base = offsetLatMeters(POI_LL, 8000);
      await makePoi(u.userId, base);

      const far = offsetLatMeters(base, 200); // outside DEDUPE_RADIUS_M (50m)
      const res = await app.inject({
        method: 'POST',
        url: '/v1/pois',
        headers: u.headers,
        payload: createPayload({
          location: far,
          gpsFix: { ...far, accuracyM: 10, capturedAt: new Date().toISOString() },
        }),
      });
      expect(res.statusCode).toBe(201);
    });
  });

  describe('GET /pois (bbox)', () => {
    it('zoom >= 13 returns the POI in bbox; zoom < 13 returns a cluster with count', async () => {
      const u = await makeUser();
      const ll = offsetLatMeters(POI_LL, 12_000);
      const poiId = await makePoi(u.userId, ll);
      const d = 0.01;
      const bbox = `${ll.lng - d},${ll.lat - d},${ll.lng + d},${ll.lat + d}`;

      const zoomed = await app.inject({ method: 'GET', url: `/v1/pois?bbox=${bbox}&zoom=15` });
      expect(zoomed.statusCode).toBe(200);
      const zoomedBody = zoomed.json();
      expect(zoomedBody.clusters).toEqual([]);
      expect(zoomedBody.pois.map((p: { id: string }) => p.id)).toContain(poiId);

      const clustered = await app.inject({ method: 'GET', url: `/v1/pois?bbox=${bbox}&zoom=10` });
      expect(clustered.statusCode).toBe(200);
      const clusteredBody = clustered.json();
      expect(clusteredBody.pois).toEqual([]);
      expect(clusteredBody.clusters.length).toBeGreaterThan(0);
      const totalCount = clusteredBody.clusters.reduce(
        (sum: number, c: { count: number }) => sum + c.count,
        0,
      );
      expect(totalCount).toBeGreaterThanOrEqual(1);
    });

    it('oversized bbox at zoom >= 13 → 400 request/invalid', async () => {
      const res = await app.inject({
        method: 'GET',
        url: `/v1/pois?bbox=${POI_LL.lng - 3},${POI_LL.lat - 3},${POI_LL.lng + 3},${POI_LL.lat + 3}&zoom=15`,
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe('request/invalid');
    });

    it('antimeridian bbox (w > e) → 400 request/invalid', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/v1/pois?bbox=170,10,-170,20&zoom=15',
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe('request/invalid');
    });
  });

  describe('GET /pois/nearby', () => {
    it('orders by distance', async () => {
      const u = await makeUser();
      const center = offsetLatMeters(POI_LL, 20_000);
      const far = offsetLatMeters(center, 400);
      const near = offsetLatMeters(center, 100);
      const nearId = await makePoi(u.userId, near);
      const farId = await makePoi(u.userId, far);

      const res = await app.inject({
        method: 'GET',
        url: `/v1/pois/nearby?lat=${center.lat}&lng=${center.lng}&radiusM=1000`,
      });
      expect(res.statusCode).toBe(200);
      const ids = res.json().pois.map((p: { id: string }) => p.id);
      expect(ids.indexOf(nearId)).toBeLessThan(ids.indexOf(farId));
    });

    it('SPEC §19: thumbnailUrl is the best-voted approved photo, null with no approved photo', async () => {
      const u = await makeUser();
      const center = offsetLatMeters(POI_LL, 60_000);
      const withPhoto = await makePoi(u.userId, offsetLatMeters(center, 50));
      const withoutPhoto = await makePoi(u.userId, offsetLatMeters(center, 100));
      const lowVoteKey = `photos/${withPhoto}/${uuidv7()}.jpg`;
      const highVoteKey = `photos/${withPhoto}/${uuidv7()}.jpg`;
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation, vote_score)
        VALUES (${uuidv7()}, ${withPhoto}, ${u.userId}, ${lowVoteKey}, 'poi_creation', 'approved', 1)`;
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation, vote_score)
        VALUES (${uuidv7()}, ${withPhoto}, ${u.userId}, ${highVoteKey}, 'poi_creation', 'approved', 5)`;

      const res = await app.inject({
        method: 'GET',
        url: `/v1/pois/nearby?lat=${center.lat}&lng=${center.lng}&radiusM=1000`,
      });
      const pois = res.json().pois as { id: string; thumbnailUrl: string | null }[];
      expect(pois.find((p) => p.id === withPhoto)?.thumbnailUrl).toBe(
        `/media/thumb/${highVoteKey}`,
      );
      expect(pois.find((p) => p.id === withoutPhoto)?.thumbnailUrl).toBeNull();
    });
  });

  describe('GET /pois/:id', () => {
    it('gallery includes only approved photos', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 30_000));
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
        VALUES (${uuidv7()}, ${poiId}, ${u.userId}, ${`photos/${poiId}/${uuidv7()}.jpg`}, 'poi_creation', 'approved')`;
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
        VALUES (${uuidv7()}, ${poiId}, ${u.userId}, ${`photos/${poiId}/${uuidv7()}.jpg`}, 'poi_creation', 'pending')`;

      const res = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(res.statusCode).toBe(200);
      const { poi } = res.json();
      expect(poi.gallery.length).toBe(1);
      expect(poi.gallery[0].status).toBe('approved');
    });

    it("SPEC §19: thumbnailUrl mirrors the gallery's first (best) entry, null with no approved photo", async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 31_000));

      const noPhoto = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(noPhoto.json().poi.thumbnailUrl).toBeNull();

      const storageKey = `photos/${poiId}/${uuidv7()}.jpg`;
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
        VALUES (${uuidv7()}, ${poiId}, ${u.userId}, ${storageKey}, 'poi_creation', 'approved')`;

      const withPhoto = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(withPhoto.json().poi.thumbnailUrl).toBe(withPhoto.json().poi.gallery[0].urlThumb);
    });

    it('removed POI → 404 resource/not_found', async () => {
      const u = await makeUser();
      const poiId = await makePoi(
        u.userId,
        offsetLatMeters(POI_LL, 40_000),
        'landmark',
        75,
        'removed',
      );
      const res = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(res.statusCode).toBe(404);
      expect(res.json().error.code).toBe('resource/not_found');
    });

    it("myVote reflects the caller's own vote, false for an anonymous caller (SPEC §7)", async () => {
      const owner = await makeUser();
      const poiId = await makePoi(owner.userId, offsetLatMeters(POI_LL, 41_000));
      const photoId = uuidv7();
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
        VALUES (${photoId}, ${poiId}, ${owner.userId}, ${`photos/${poiId}/${photoId}.jpg`}, 'poi_creation', 'approved')`;

      const anonymous = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(anonymous.json().poi.gallery[0].myVote).toBe(false);

      const voter = await makeUser();
      const beforeVoting = await app.inject({
        method: 'GET',
        url: `/v1/pois/${poiId}`,
        headers: voter.headers,
      });
      expect(beforeVoting.json().poi.gallery[0].myVote).toBe(false);

      await app.inject({
        method: 'POST',
        url: `/v1/photos/${photoId}/vote`,
        headers: voter.headers,
        payload: { value: 1 },
      });

      const afterVoting = await app.inject({
        method: 'GET',
        url: `/v1/pois/${poiId}`,
        headers: voter.headers,
      });
      expect(afterVoting.json().poi.gallery[0].myVote).toBe(true);
      // A different caller's own vote state is unaffected by voter's vote.
      const otherCaller = await app.inject({
        method: 'GET',
        url: `/v1/pois/${poiId}`,
        headers: owner.headers,
      });
      expect(otherCaller.json().poi.gallery[0].myVote).toBe(false);
    });
  });

  describe('POST /pois/:id/save (SPEC §19)', () => {
    it("saves then unsaves, reflected in GET /me/map's saved array", async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 41_000));

      const save = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/save`,
        headers: u.headers,
        payload: { value: 1 },
      });
      expect(save.statusCode).toBe(200);
      expect(save.json()).toEqual({ saved: true });

      const map = await app.inject({
        method: 'GET',
        url: '/v1/me/map',
        headers: u.headers,
      });
      expect(map.json().saved.map((p: { id: string }) => p.id)).toEqual([poiId]);

      const unsave = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/save`,
        headers: u.headers,
        payload: { value: 0 },
      });
      expect(unsave.statusCode).toBe(200);
      expect(unsave.json()).toEqual({ saved: false });

      const mapAfter = await app.inject({
        method: 'GET',
        url: '/v1/me/map',
        headers: u.headers,
      });
      expect(mapAfter.json().saved).toEqual([]);
    });

    it('saving twice is idempotent, no duplicate row/error', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 42_000));

      await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/save`,
        headers: u.headers,
        payload: { value: 1 },
      });
      const second = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/save`,
        headers: u.headers,
        payload: { value: 1 },
      });
      expect(second.statusCode).toBe(200);

      const map = await app.inject({
        method: 'GET',
        url: '/v1/me/map',
        headers: u.headers,
      });
      expect(map.json().saved).toHaveLength(1);
    });

    it('saving a removed POI → 404 resource/not_found', async () => {
      const u = await makeUser();
      const poiId = await makePoi(
        u.userId,
        offsetLatMeters(POI_LL, 43_000),
        'landmark',
        75,
        'removed',
      );
      const res = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/save`,
        headers: u.headers,
        payload: { value: 1 },
      });
      expect(res.statusCode).toBe(404);
      expect(res.json().error.code).toBe('resource/not_found');
    });
  });

  describe('photo presign/complete', () => {
    it('presign rejects a disallowed mime → 400 request/invalid', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 50_000));
      const res = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/gif', source: 'poi_creation' },
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error.code).toBe('request/invalid');
    });

    it('presign happy path returns uploadUrl/storageKey/maxBytes', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 51_000));
      const res = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/jpeg', source: 'poi_creation' },
      });
      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.storageKey).toMatch(new RegExp(`^photos/${poiId}/[0-9a-f-]{36}\\.jpg$`));
      expect(body.maxBytes).toBe(SPEC_CONSTANTS.photos.UPLOAD_MAX_BYTES);
      expect(body.uploadUrl).toContain(body.storageKey);
    });

    it('complete happy path → 201 pending row', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 52_000));
      const presign = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/jpeg', source: 'poi_creation' },
      });
      storage.headResult = { bytes: 500_000, contentType: 'image/jpeg' };
      const complete = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: u.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(complete.statusCode).toBe(201);
      const { photo } = complete.json();
      // The response is a snapshot of the freshly-inserted row (SPEC §6 M1 note) — it
      // reflects 'pending' even though moderation has already run by the time we get here.
      expect(photo.status).toBe('pending');
      expect(photo.uploader.handle).toBeTruthy();
      // Dev provider is synchronous and always approves, so the DB has already moved on.
      const row = await handle.pg`SELECT moderation FROM photos WHERE id = ${photo.id}`;
      expect(row[0]?.moderation).toBe('approved');
      expect(moderation.calls).toContainEqual({
        photoId: photo.id,
        storageKey: presign.json().storageKey,
      });

      // Idempotent retry (lost response): same caller re-completes → same photo, no 500.
      const retry = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: u.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(retry.statusCode).toBe(201);
      expect(retry.json().photo.id).toBe(photo.id);

      // A different user completing the same key → request/invalid, not a hijack.
      const other = await makeUser();
      const hijack = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: other.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(hijack.statusCode).toBe(400);
    });

    it('complete with missing object (head() = null) → 422 photo/rejected', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 53_000));
      const presign = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/jpeg', source: 'poi_creation' },
      });
      storage.headResult = null;
      const complete = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: u.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(complete.statusCode).toBe(422);
      expect(complete.json().error.code).toBe('photo/rejected');
      expect(complete.json().error.details.reason).toBe('quality');
      storage.headResult = { bytes: 500_000, contentType: 'image/jpeg' };
    });

    it('complete with an oversized object → 422 photo/rejected', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 54_000));
      const presign = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/jpeg', source: 'poi_creation' },
      });
      storage.headResult = {
        bytes: SPEC_CONSTANTS.photos.UPLOAD_MAX_BYTES + 1,
        contentType: 'image/jpeg',
      };
      const complete = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: u.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(complete.statusCode).toBe(422);
      expect(complete.json().error.code).toBe('photo/rejected');
      storage.headResult = { bytes: 500_000, contentType: 'image/jpeg' };
    });

    it('a rejected moderation verdict lands in the DB and the photo never reaches the public gallery', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 55_000));
      const presign = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/jpeg', source: 'poi_creation' },
      });
      moderation.nextVerdict = { outcome: 'rejected', reason: 'people' };
      const complete = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: u.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(complete.statusCode).toBe(201); // moderation verdict never affects the HTTP outcome
      const photoId = complete.json().photo.id;

      const row = await handle.pg`
        SELECT moderation, rejection_reason FROM photos WHERE id = ${photoId}`;
      expect(row[0]?.moderation).toBe('rejected');
      expect(row[0]?.rejection_reason).toBe('people');

      const detail = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(detail.json().poi.gallery).toEqual([]);
    });

    it('an escalated verdict is stored but stays out of the gallery (no reviewer surface yet)', async () => {
      const u = await makeUser();
      const poiId = await makePoi(u.userId, offsetLatMeters(POI_LL, 56_000));
      const presign = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/presign`,
        headers: u.headers,
        payload: { contentType: 'image/jpeg', source: 'poi_creation' },
      });
      moderation.nextVerdict = { outcome: 'escalated' };
      const complete = await app.inject({
        method: 'POST',
        url: `/v1/pois/${poiId}/photos/complete`,
        headers: u.headers,
        payload: { storageKey: presign.json().storageKey, source: 'poi_creation' },
      });
      expect(complete.statusCode).toBe(201);
      const row = await handle.pg`
        SELECT moderation FROM photos WHERE id = ${complete.json().photo.id}`;
      expect(row[0]?.moderation).toBe('escalated');

      const detail = await app.inject({ method: 'GET', url: `/v1/pois/${poiId}` });
      expect(detail.json().poi.gallery).toEqual([]);
    });
  });
});
