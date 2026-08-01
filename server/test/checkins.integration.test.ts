// SPEC §5 end-to-end against real PostGIS: happy paths, every rejection layer, nonce
// replay, duplicate rules, retry-after-rejection, trust events, coverage side effects.
import { createHash, randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { SPEC_CONSTANTS } from '../src/constants.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

const POI_LL = { lat: 38.7139, lng: -9.13 }; // Lisbon
const FAR_LL = { lat: 41.1579, lng: -8.6291 }; // Porto

describe.runIf(!!url)('check-in pipeline (SPEC §5)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;
  let auth: { headers: { authorization: string }; userId: string };
  let deviceId: string;
  let poiId: string;

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `ci-${randomUUID().slice(0, 12)}@example.com`;
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

  async function makePoi(creatorId: string, ll = POI_LL, radiusM = 75): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${id}, ${creatorId}, ${'Miradouro de Teste'}, 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll))}, ${radiusM}, 'active')`;
    return id;
  }

  function fixes(ll = POI_LL, accuracyM = 20, nowMs = Date.now()) {
    return [
      { ...ll, accuracyM, capturedAt: new Date(nowMs - 10_000).toISOString() },
      { ...ll, accuracyM, capturedAt: new Date(nowMs).toISOString() },
    ];
  }

  async function intent(poi = poiId, device = deviceId, headers = auth.headers) {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/checkins/intent',
      headers,
      payload: { poiId: poi, deviceId: device },
    });
    return res;
  }

  async function submit(
    nonce: string,
    overrides: Record<string, unknown> = {},
    headers = auth.headers,
  ) {
    return app.inject({
      method: 'POST',
      url: '/v1/checkins',
      headers,
      payload: {
        nonce,
        poiId,
        mode: 'confirm',
        fixes: fixes(),
        integrityToken: `dev.pass.${nonce}`,
        ...overrides,
      },
    });
  }

  beforeAll(async () => {
    await migrate(url as string, () => {});
    handle = createDb(url as string);
    const config = loadConfig({
      JWT_SECRET: 'test-secret-that-is-at-least-32-chars!!',
      NODE_ENV: 'test',
      DATABASE_URL: url,
    });
    app = buildApp({
      config,
      dbHandle: handle,
      storage: createR2Storage(config),
      moderation: devModerationProvider(() => {}),
    });
    auth = await makeUser();
    deviceId = await makeDevice(auth.headers);
    poiId = await makePoi(auth.userId);
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('happy path: intent → submit → verified, coverage + counter side effects', async () => {
    const i = await intent();
    expect(i.statusCode).toBe(200);
    const { nonce, expiresInS } = i.json();
    expect(expiresInS).toBe(SPEC_CONSTANTS.nonce.CHECKIN_NONCE_TTL_S);

    const res = await submit(nonce);
    expect(res.statusCode).toBe(201);
    const { checkin } = res.json();
    expect(checkin.status).toBe('verified');
    expect(checkin.verifiedAt).toBeTruthy();

    const cov =
      await handle.pg`SELECT count(*)::int AS n FROM user_coverage WHERE user_id = ${auth.userId}`;
    expect(cov[0]?.n).toBe(1);
    const cnt = await handle.pg`SELECT checkin_count FROM pois WHERE id = ${poiId}`;
    expect(cnt[0]?.checkin_count).toBe(1);

    const get = await app.inject({
      method: 'GET',
      url: `/v1/checkins/${checkin.id}`,
      headers: auth.headers,
    });
    expect(get.statusCode).toBe(200);
    expect(get.json().checkin.status).toBe('verified');
  });

  it('duplicate: second intent for the same POI → 409', async () => {
    const res = await intent();
    expect(res.statusCode).toBe(409);
    expect(res.json().error.code).toBe('checkin/duplicate');
  });

  it('non-owner GET → 404 (no existence leak)', async () => {
    const other = await makeUser();
    const rows = await handle.pg`SELECT id FROM checkins WHERE user_id = ${auth.userId} LIMIT 1`;
    const res = await app.inject({
      method: 'GET',
      url: `/v1/checkins/${rows[0]?.id}`,
      headers: other.headers,
    });
    expect(res.statusCode).toBe(404);
  });

  describe('with a fresh user each scenario', () => {
    let u: { headers: { authorization: string }; userId: string };
    let d: string;
    let p: string;

    async function fresh(ll = POI_LL, radiusM = 75) {
      u = await makeUser();
      d = await makeDevice(u.headers);
      p = await makePoi(u.userId, ll, radiusM);
    }

    async function freshIntent() {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/checkins/intent',
        headers: u.headers,
        payload: { poiId: p, deviceId: d },
      });
      expect(res.statusCode).toBe(200);
      return res.json().nonce as string;
    }

    function freshSubmit(nonce: string, overrides: Record<string, unknown> = {}) {
      return app.inject({
        method: 'POST',
        url: '/v1/checkins',
        headers: u.headers,
        payload: {
          nonce,
          poiId: p,
          mode: 'confirm',
          fixes: fixes(),
          integrityToken: `dev.pass.${nonce}`,
          ...overrides,
        },
      });
    }

    it('nonce replay → second submit gets 410', async () => {
      await fresh();
      const nonce = await freshIntent();
      expect((await freshSubmit(nonce)).statusCode).toBe(201);
      // Delete the check-in so the replay hits the nonce guard, not the duplicate guard.
      await handle.pg`DELETE FROM checkin_evidence WHERE checkin_id IN (SELECT id FROM checkins WHERE user_id = ${u.userId})`;
      await handle.pg`DELETE FROM user_coverage WHERE user_id = ${u.userId}`;
      await handle.pg`DELETE FROM checkins WHERE user_id = ${u.userId}`;
      const replay = await freshSubmit(nonce);
      expect(replay.statusCode).toBe(410);
      expect(replay.json().error.code).toBe('checkin/nonce_expired');
    });

    it('integrity fail → 422 rejected, evidence persisted, trust drops, retry allowed', async () => {
      await fresh();
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce, { integrityToken: `dev.fail.${nonce}` });
      expect(res.statusCode).toBe(422);
      const { error } = res.json();
      expect(error.code).toBe('checkin/rejected');
      expect(error.details.reasons).toContain('integrity');

      const ev = await handle.pg`
        SELECT e.verdicts FROM checkin_evidence e JOIN checkins c ON c.id = e.checkin_id
        WHERE c.user_id = ${u.userId}`;
      expect(ev.length).toBe(1);
      const trust = await handle.pg`SELECT trust_score FROM users WHERE id = ${u.userId}`;
      expect(trust[0]?.trust_score).toBe(100 + SPEC_CONSTANTS.trust.D_INTEGRITY_FAIL);

      // SPEC §5.7: a rejected row never blocks an honest retry.
      const nonce2 = await freshIntent();
      const retry = await freshSubmit(nonce2);
      expect(retry.statusCode).toBe(201);
      expect(retry.json().checkin.status).toBe('verified');
    });

    it('degraded integrity caps at pending (no coverage yet)', async () => {
      await fresh();
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce, { integrityToken: `dev.degraded.${nonce}` });
      expect(res.statusCode).toBe(201);
      expect(res.json().checkin.status).toBe('pending');
      const cov =
        await handle.pg`SELECT count(*)::int AS n FROM user_coverage WHERE user_id = ${u.userId}`;
      expect(cov[0]?.n).toBe(0);
    });

    it('out of radius → 422 with outside_radius', async () => {
      await fresh();
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce, { fixes: fixes(FAR_LL) });
      expect(res.statusCode).toBe(422);
      expect(res.json().error.details.reasons).toContain('outside_radius');
    });

    it('teleport: verified in Lisbon then immediately at a Porto POI → pending + trust event', async () => {
      await fresh();
      const nonce = await freshIntent();
      expect((await freshSubmit(nonce)).statusCode).toBe(201);

      const porto = await makePoi(u.userId, FAR_LL);
      const i2 = await app.inject({
        method: 'POST',
        url: '/v1/checkins/intent',
        headers: u.headers,
        payload: { poiId: porto, deviceId: d },
      });
      const nonce2 = i2.json().nonce as string;
      const res = await app.inject({
        method: 'POST',
        url: '/v1/checkins',
        headers: u.headers,
        payload: {
          nonce: nonce2,
          poiId: porto,
          mode: 'confirm',
          fixes: fixes(FAR_LL),
          integrityToken: `dev.pass.${nonce2}`,
        },
      });
      expect(res.statusCode).toBe(201);
      expect(res.json().checkin.status).toBe('pending');
      const ev = await handle.pg`
        SELECT type FROM trust_events WHERE user_id = ${u.userId} AND type = 'velocity_violation'`;
      expect(ev.length).toBe(1);
    });

    it('photo mode: valid capture token verifies and links the photo', async () => {
      await fresh();
      const nonce = await freshIntent();
      const capturedAt = new Date().toISOString();
      const storageKey = `checkin/${u.userId}/${randomUUID()}.jpg`;
      await handle.pg`
        INSERT INTO photos (id, poi_id, uploader_id, storage_key, source)
        VALUES (${uuidv7()}, ${p}, ${u.userId}, ${storageKey}, 'checkin')`;
      const token = createHash('sha256')
        .update(`${nonce}.${Date.parse(capturedAt)}`)
        .digest('hex');
      const res = await freshSubmit(nonce, {
        mode: 'photo',
        capture: { token, capturedAt, storageKey },
      });
      expect(res.statusCode).toBe(201);
      expect(res.json().checkin.status).toBe('verified');
      const row = await handle.pg`SELECT photo_id FROM checkins WHERE user_id = ${u.userId}`;
      expect(row[0]?.photo_id).toBeTruthy();
    });

    it('photo mode: wrong capture token → 422 capture_invalid', async () => {
      await fresh();
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce, {
        mode: 'photo',
        capture: {
          token: 'a'.repeat(64),
          capturedAt: new Date().toISOString(),
          storageKey: 'nope.jpg',
        },
      });
      expect(res.statusCode).toBe(422);
      expect(res.json().error.details.reasons).toContain('capture_invalid');
    });

    it('low trust forces photo mode: confirm → 422 photo_required', async () => {
      await fresh();
      await handle.pg`UPDATE users SET trust_score = 30 WHERE id = ${u.userId}`;
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce);
      expect(res.statusCode).toBe(422);
      expect(res.json().error.details.reasons).toContain('photo_required');
    });

    it('imprecise-but-centered fix verifies via containment (a=140, r=75)', async () => {
      await fresh();
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce, { fixes: fixes(POI_LL, 140) });
      expect(res.statusCode).toBe(201);
      // c = (75+140-0)/280 ≈ 0.77 → pass_degraded → verified
      expect(res.json().checkin.status).toBe('verified');
    });

    it('photo mode without capture → 400 request/invalid', async () => {
      await fresh();
      const nonce = await freshIntent();
      const res = await freshSubmit(nonce, { mode: 'photo' });
      expect(res.statusCode).toBe(400);
    });
  });
});
