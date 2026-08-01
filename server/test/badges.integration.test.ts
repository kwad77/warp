// SPEC §16 (M2) — badge awarding end-to-end through the real POST /checkins pipeline
// (not raw inserts), against real PostGIS.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { coverageCell, coverageCentroid, dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

function offsetLngMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat, lng: ll.lng + meters / (111_320 * Math.cos((ll.lat * Math.PI) / 180)) };
}

// Salted per run, on BOTH axes, so this suite's "brand-new cell" assumptions never
// collide with rows a previous run left behind in this shared, never-reset dev/test
// database. A latitude-only salt (as other integration suites use, safely, since they
// only need to keep their own cases apart from each other) collapses this suite's random
// space to a single ~4,000km line at a fixed longitude — and this suite uniquely depends
// on TRUE global first-ever-covered-cell uniqueness, so that line eventually saturates
// against its own history. Salting longitude too spreads runs across a ~4,000km square
// instead, making an accidental collision astronomically less likely.
const RUN_ORIGIN = offsetLngMeters(
  offsetLatMeters({ lat: -10.0, lng: 100.0 }, Math.floor(Math.random() * 4_000_000)),
  Math.floor(Math.random() * 4_000_000),
);

describe.runIf(!!url)('badges (SPEC §16)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `badge-${randomUUID().slice(0, 12)}@example.com`;
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

  async function makePoi(creatorId: string, ll: { lat: number; lng: number }): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${id}, ${creatorId}, 'Badge Test POI', 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll))}, 75, 'active')`;
    return id;
  }

  function fixes(ll: { lat: number; lng: number }, nowMs = Date.now()) {
    return [
      { ...ll, accuracyM: 20, capturedAt: new Date(nowMs - 10_000).toISOString() },
      { ...ll, accuracyM: 20, capturedAt: new Date(nowMs).toISOString() },
    ];
  }

  /** Drives a real verified check-in through intent → submit for [userId] at [poiId]/[ll]. */
  async function checkIn(
    headers: { authorization: string },
    deviceId: string,
    poiId: string,
    ll: { lat: number; lng: number },
  ) {
    const intentRes = await app.inject({
      method: 'POST',
      url: '/v1/checkins/intent',
      headers,
      payload: { poiId, deviceId },
    });
    expect(intentRes.statusCode).toBe(200);
    const { nonce } = intentRes.json();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/checkins',
      headers,
      payload: {
        nonce,
        poiId,
        mode: 'confirm',
        fixes: fixes(ll),
        integrityToken: `dev.pass.${nonce}`,
      },
    });
    expect(res.statusCode).toBe(201);
    expect(res.json().checkin.status).toBe('verified');
    return res;
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
      oidcVerifiers: { apple: null, google: null },
    });
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('first_in_region: the first verified check-in in a brand-new cell awards the badge', async () => {
    const creator = await makeUser();
    const checker = await makeUser();
    const device = await makeDevice(checker.headers);
    const ll = offsetLatMeters(RUN_ORIGIN, 50_000);
    const poiId = await makePoi(creator.userId, ll);

    await checkIn(checker.headers, device, poiId, ll);

    const rows = await handle.pg`SELECT badge_key FROM badges WHERE user_id = ${checker.userId}`;
    expect(rows.map((r) => r.badge_key)).toEqual(['first_in_region']);
  });

  it('first_in_region: a second user in an ALREADY-covered cell does not get the badge', async () => {
    const creator = await makeUser();
    const first = await makeUser();
    const firstDevice = await makeDevice(first.headers);
    const ll = offsetLatMeters(RUN_ORIGIN, 100_000);
    const poiA = await makePoi(creator.userId, ll);
    await checkIn(first.headers, firstDevice, poiA, ll);

    // A second, distinct user + distinct POI, but positioned so its coverage cell (r7,
    // ~5km²) is the SAME one `first` already covered. Using the cell's own centroid
    // (rather than an arbitrary small offset from `ll`) guarantees this deterministically
    // — an arbitrary offset can flake if `ll` happens to land near a cell boundary.
    const second = await makeUser();
    const secondDevice = await makeDevice(second.headers);
    const nearbyLl = coverageCentroid(coverageCell(ll));
    const poiB = await makePoi(creator.userId, nearbyLl);
    await checkIn(second.headers, secondDevice, poiB, nearbyLl);

    const rows = await handle.pg`SELECT badge_key FROM badges WHERE user_id = ${second.userId}`;
    expect(rows).toEqual([]);
  });

  it('poi_milestone_10: awarded to the POI creator (not the checker-in), not the milestone threshold itself', async () => {
    const creator = await makeUser();
    const checker = await makeUser();
    const device = await makeDevice(checker.headers);
    const ll = offsetLatMeters(RUN_ORIGIN, 150_000);
    const poiId = await makePoi(creator.userId, ll);
    await handle.pg`UPDATE pois SET checkin_count = 9 WHERE id = ${poiId}`;

    await checkIn(checker.headers, device, poiId, ll);

    const creatorBadges =
      await handle.pg`SELECT badge_key FROM badges WHERE user_id = ${creator.userId}`;
    expect(creatorBadges.map((r) => r.badge_key)).toContain('poi_milestone_10');
    const checkerBadges =
      await handle.pg`SELECT badge_key FROM badges WHERE user_id = ${checker.userId} AND badge_key::text LIKE 'poi_milestone%'`;
    expect(checkerBadges).toEqual([]);
  });

  it('poi_milestone: jumping straight past multiple thresholds awards all of them at once', async () => {
    const creator = await makeUser();
    const checker = await makeUser();
    const device = await makeDevice(checker.headers);
    const ll = offsetLatMeters(RUN_ORIGIN, 200_000);
    const poiId = await makePoi(creator.userId, ll);
    await handle.pg`UPDATE pois SET checkin_count = 49 WHERE id = ${poiId}`;

    await checkIn(checker.headers, device, poiId, ll);

    const rows = await handle.pg`
      SELECT badge_key FROM badges WHERE user_id = ${creator.userId} AND badge_key::text LIKE 'poi_milestone%'
      ORDER BY badge_key`;
    expect(rows.map((r) => r.badge_key).sort()).toEqual(['poi_milestone_10', 'poi_milestone_50']);
  });

  it('GET /me/badges returns the caller badges ordered by awardedAt', async () => {
    const creator = await makeUser();
    const checker = await makeUser();
    const device = await makeDevice(checker.headers);
    const ll = offsetLatMeters(RUN_ORIGIN, 250_000);
    const poiId = await makePoi(creator.userId, ll);

    await checkIn(checker.headers, device, poiId, ll);

    const res = await app.inject({
      method: 'GET',
      url: '/v1/me/badges',
      headers: checker.headers,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().badges).toEqual([
      { badgeKey: 'first_in_region', awardedAt: expect.any(String) },
    ]);
  });

  it('a rejected check-in never awards a badge', async () => {
    const creator = await makeUser();
    const checker = await makeUser();
    const device = await makeDevice(checker.headers);
    const ll = offsetLatMeters(RUN_ORIGIN, 300_000);
    const farAwayLl = offsetLatMeters(ll, 5_000); // outside the check-in radius
    const poiId = await makePoi(creator.userId, ll);

    const intentRes = await app.inject({
      method: 'POST',
      url: '/v1/checkins/intent',
      headers: checker.headers,
      payload: { poiId, deviceId: device },
    });
    const { nonce } = intentRes.json();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/checkins',
      headers: checker.headers,
      payload: {
        nonce,
        poiId,
        mode: 'confirm',
        fixes: fixes(farAwayLl),
        integrityToken: `dev.pass.${nonce}`,
      },
    });
    expect(res.statusCode).toBe(422);

    const rows = await handle.pg`SELECT badge_key FROM badges WHERE user_id = ${checker.userId}`;
    expect(rows).toEqual([]);
  });
});
