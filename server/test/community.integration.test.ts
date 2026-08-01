// SPEC §7 — photo voting and reporting, against real PostGIS.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

const BASE_LL = { lat: 51.0, lng: -1.0 };
const RUN_SALT_M = Math.floor(Math.random() * 400_000);

describe.runIf(!!url)('community: votes + reports (SPEC §7)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `com-${randomUUID().slice(0, 12)}@example.com`;
    const { requestEmailCode } = await import('../src/auth/service.js');
    let code = '';
    await requestEmailCode(
      handle.db,
      {
        sendLoginCode: async (_e: string, c: string) => {
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
    return {
      headers: { authorization: `Bearer ${res.json().accessToken}` },
      userId: res.json().user.id,
    };
  }

  async function makePoi(creatorId: string, ll: { lat: number; lng: number }): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${id}, ${creatorId}, 'x', 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll)).toString()}, 75, 'active')`;
    return id;
  }

  async function makePhoto(
    poiId: string,
    uploaderId: string,
    moderation: 'pending' | 'approved' | 'rejected' = 'approved',
  ): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
      VALUES (${id}, ${poiId}, ${uploaderId}, ${`photos/${poiId}/${id}.jpg`}, 'poi_creation', ${moderation})`;
    return id;
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
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('vote → voteScore increments; second identical vote is idempotent; retract → decrements', async () => {
    const owner = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M);
    const poiId = await makePoi(owner.userId, ll);
    const photoId = await makePhoto(poiId, owner.userId);

    const voter1 = await makeUser();
    const v1 = await app.inject({
      method: 'POST',
      url: `/v1/photos/${photoId}/vote`,
      headers: voter1.headers,
      payload: { value: 1 },
    });
    expect(v1.statusCode).toBe(200);
    expect(v1.json().voteScore).toBe(1);

    // Same voter votes again — idempotent, not double-counted.
    const v1Again = await app.inject({
      method: 'POST',
      url: `/v1/photos/${photoId}/vote`,
      headers: voter1.headers,
      payload: { value: 1 },
    });
    expect(v1Again.json().voteScore).toBe(1);

    const voter2 = await makeUser();
    const v2 = await app.inject({
      method: 'POST',
      url: `/v1/photos/${photoId}/vote`,
      headers: voter2.headers,
      payload: { value: 1 },
    });
    expect(v2.json().voteScore).toBe(2);

    const retract = await app.inject({
      method: 'POST',
      url: `/v1/photos/${photoId}/vote`,
      headers: voter1.headers,
      payload: { value: 0 },
    });
    expect(retract.json().voteScore).toBe(1);

    const row = await handle.pg`SELECT vote_score FROM photos WHERE id = ${photoId}`;
    expect(row[0]?.vote_score).toBe(1);
  });

  it('voting on a non-approved photo → 404 resource/not_found (no review-state leak)', async () => {
    const owner = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 5_000);
    const poiId = await makePoi(owner.userId, ll);
    const photoId = await makePhoto(poiId, owner.userId, 'pending');

    const voter = await makeUser();
    const res = await app.inject({
      method: 'POST',
      url: `/v1/photos/${photoId}/vote`,
      headers: voter.headers,
      payload: { value: 1 },
    });
    expect(res.statusCode).toBe(404);
  });

  it('report a POI → 201; report an unknown target → 404', async () => {
    const owner = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 10_000);
    const poiId = await makePoi(owner.userId, ll);
    const reporter = await makeUser();

    const res = await app.inject({
      method: 'POST',
      url: '/v1/reports',
      headers: reporter.headers,
      payload: { targetType: 'poi', targetId: poiId, reason: 'wrong_location', note: 'off by 2km' },
    });
    expect(res.statusCode).toBe(201);
    expect(res.json().ok).toBe(true);

    const row = await handle.pg`SELECT reason, note FROM reports WHERE target_id = ${poiId}`;
    expect(row[0]?.reason).toBe('wrong_location');

    const unknown = await app.inject({
      method: 'POST',
      url: '/v1/reports',
      headers: reporter.headers,
      payload: { targetType: 'poi', targetId: uuidv7(), reason: 'other' },
    });
    expect(unknown.statusCode).toBe(404);
  });

  it('report rate limit: 21st report today → 429', async () => {
    const reporter = await makeUser();
    const targets: string[] = [];
    for (let i = 0; i < 21; i++) {
      targets.push(
        await makePoi(reporter.userId, offsetLatMeters(BASE_LL, RUN_SALT_M + 50_000 + i * 200)),
      );
    }
    let last: Awaited<ReturnType<typeof app.inject>> | undefined;
    for (const targetId of targets) {
      last = await app.inject({
        method: 'POST',
        url: '/v1/reports',
        headers: reporter.headers,
        payload: { targetType: 'poi', targetId, reason: 'other' },
      });
    }
    expect(last?.statusCode).toBe(429);
    expect(last?.json().error.code).toBe('rate/limited');
  });

  it('unauthenticated vote/report → 401 auth/missing', async () => {
    const owner = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 90_000);
    const poiId = await makePoi(owner.userId, ll);
    const photoId = await makePhoto(poiId, owner.userId);

    const vote = await app.inject({
      method: 'POST',
      url: `/v1/photos/${photoId}/vote`,
      payload: { value: 1 },
    });
    expect(vote.statusCode).toBe(401);

    const report = await app.inject({
      method: 'POST',
      url: '/v1/reports',
      payload: { targetType: 'poi', targetId: poiId, reason: 'other' },
    });
    expect(report.statusCode).toBe(401);
  });
});
