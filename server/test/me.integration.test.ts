// SPEC §7 — /me surface, against real PostGIS.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { coverageCell, dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

const BASE_LL = { lat: 12.0, lng: 40.0 };
const RUN_SALT_M = Math.floor(Math.random() * 400_000);

describe.runIf(!!url)('/me (SPEC §7)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `me-${randomUUID().slice(0, 12)}@example.com`;
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

  async function makePoi(creatorId: string, ll: { lat: number; lng: number }): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${id}, ${creatorId}, ${'Test POI'}, 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll)).toString()}, 75, 'active')`;
    return id;
  }

  async function makeVerifiedCheckin(
    userId: string,
    poiId: string,
    ll: { lat: number; lng: number },
    createdAt?: Date,
  ): Promise<string> {
    const id = uuidv7();
    const cell = h3ToBigint(coverageCell(ll)).toString();
    await handle.pg`
      INSERT INTO checkins (id, user_id, poi_id, mode, status, h3_r7, created_at, verified_at)
      VALUES (${id}, ${userId}, ${poiId}, 'confirm', 'verified', ${cell},
              ${(createdAt ?? new Date()).toISOString()}, ${(createdAt ?? new Date()).toISOString()})`;
    await handle.pg`
      INSERT INTO user_coverage (user_id, h3_r7, first_checkin_id, created_at)
      VALUES (${userId}, ${cell}, ${id}, ${(createdAt ?? new Date()).toISOString()})
      ON CONFLICT DO NOTHING`;
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
      oidcVerifiers: { apple: null, google: null },
    });
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('GET /me: stats reflect verified checkins, coverage cells, and non-removed created POIs', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 1_000);
    const poi = await makePoi(u.userId, ll);
    await makeVerifiedCheckin(u.userId, poi, offsetLatMeters(ll, 10));

    // a removed POI the user created must NOT count
    const removedPoi = await makePoi(u.userId, offsetLatMeters(ll, 5_000));
    await handle.pg`UPDATE pois SET status = 'removed' WHERE id = ${removedPoi}`;

    const res = await app.inject({ method: 'GET', url: '/v1/me', headers: u.headers });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.user.handle).toMatch(/^explorer_/);
    // makeVerifiedCheckin inserts checkins/user_coverage directly and doesn't touch
    // pois.checkin_count (that increment only happens inside submitCheckin's own
    // transaction — covered by checkins.integration.test.ts), so creatorScore is 0 here.
    expect(body.stats).toMatchObject({
      checkins: 1,
      cellsCovered: 1,
      poisCreated: 1,
      creatorScore: 0,
    });
  });

  it('GET /me: creatorScore sums checkin_count across non-removed created POIs only (SPEC §16)', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 8_000);
    const poiA = await makePoi(u.userId, ll);
    const poiB = await makePoi(u.userId, offsetLatMeters(ll, 3_000));
    const removedPoi = await makePoi(u.userId, offsetLatMeters(ll, 6_000));
    await handle.pg`UPDATE pois SET checkin_count = 7 WHERE id = ${poiA}`;
    await handle.pg`UPDATE pois SET checkin_count = 5 WHERE id = ${poiB}`;
    await handle.pg`UPDATE pois SET checkin_count = 100, status = 'removed' WHERE id = ${removedPoi}`;

    const res = await app.inject({ method: 'GET', url: '/v1/me', headers: u.headers });

    expect(res.statusCode).toBe(200);
    expect(res.json().stats.creatorScore).toBe(12);
  });

  it('GET /me/map: checkedIn, created, and always-empty vaulted', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 2_000);
    const poi = await makePoi(u.userId, ll);
    await makeVerifiedCheckin(u.userId, poi, offsetLatMeters(ll, 10));
    const createdOnly = await makePoi(u.userId, offsetLatMeters(ll, 20_000));

    const res = await app.inject({ method: 'GET', url: '/v1/me/map', headers: u.headers });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.checkedIn.map((p: { id: string }) => p.id)).toEqual([poi]);
    expect(body.created.map((p: { id: string }) => p.id).sort()).toEqual([poi, createdOnly].sort());
    expect(body.vaulted).toEqual([]);
  });

  it('GET /me/coverage: returns h3 r7 cells as lowercase hex strings', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 3_000);
    const poi = await makePoi(u.userId, ll);
    await makeVerifiedCheckin(u.userId, poi, ll);

    const res = await app.inject({ method: 'GET', url: '/v1/me/coverage', headers: u.headers });
    expect(res.statusCode).toBe(200);
    expect(res.json().count).toBe(1);
    expect(res.json().cells[0]).toMatch(/^[0-9a-f]+$/);
  });

  it('GET /me/coverage/heatmap: zoom < 4 buckets distinct r7 cells into one res-2 ancestor', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 3_500);
    const poiA = await makePoi(u.userId, ll);
    const poiB = await makePoi(u.userId, offsetLatMeters(ll, 5_000)); // distinct r7, same res-2
    await makeVerifiedCheckin(u.userId, poiA, ll);
    await makeVerifiedCheckin(u.userId, poiB, offsetLatMeters(ll, 5_000));

    const res = await app.inject({
      method: 'GET',
      url: '/v1/me/coverage/heatmap?zoom=2',
      headers: u.headers,
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.resolution).toBe(2);
    expect(body.cells).toHaveLength(1);
    expect(body.cells[0]).toMatchObject({ count: 2 });
    expect(body.cells[0].centroid.lat).toBeTypeOf('number');
  });

  it('GET /me/coverage/heatmap: zoom in [9,13) is resolution 7 — one cell per r7 (no bucketing)', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 3_600);
    const poiA = await makePoi(u.userId, ll);
    const poiB = await makePoi(u.userId, offsetLatMeters(ll, 5_000));
    await makeVerifiedCheckin(u.userId, poiA, ll);
    await makeVerifiedCheckin(u.userId, poiB, offsetLatMeters(ll, 5_000));

    const res = await app.inject({
      method: 'GET',
      url: '/v1/me/coverage/heatmap?zoom=10',
      headers: u.headers,
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.resolution).toBe(7);
    expect(body.cells).toHaveLength(2);
    expect(body.cells.every((c: { count: number }) => c.count === 1)).toBe(true);
  });

  it('GET /me/coverage/heatmap: zoom >= 13 (pin-mode threshold) returns an empty heatmap', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 3_700);
    const poi = await makePoi(u.userId, ll);
    await makeVerifiedCheckin(u.userId, poi, ll);

    const res = await app.inject({
      method: 'GET',
      url: '/v1/me/coverage/heatmap?zoom=13',
      headers: u.headers,
    });

    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ cells: [], resolution: null });
  });

  it('GET /me/checkins: keyset pagination walks the full history with no duplicates/gaps', async () => {
    const u = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 4_000);
    const ids: string[] = [];
    for (let i = 0; i < 5; i++) {
      const poi = await makePoi(u.userId, offsetLatMeters(ll, i * 200));
      const createdAt = new Date(Date.now() - (5 - i) * 60_000);
      ids.push(await makeVerifiedCheckin(u.userId, poi, offsetLatMeters(ll, i * 200), createdAt));
    }

    const seen: string[] = [];
    let cursor: string | undefined;
    for (let page = 0; page < 10; page++) {
      const qs = new URLSearchParams({ limit: '2', ...(cursor ? { cursor } : {}) });
      const res = await app.inject({
        method: 'GET',
        url: `/v1/me/checkins?${qs.toString()}`,
        headers: u.headers,
      });
      expect(res.statusCode).toBe(200);
      const body = res.json();
      seen.push(...body.items.map((i: { id: string }) => i.id));
      if (!body.nextCursor) break;
      cursor = body.nextCursor;
    }
    expect(seen).toEqual([...ids].reverse());
    expect(new Set(seen).size).toBe(seen.length);
  });

  it('DELETE /me: soft-deletes and revokes refresh tokens (immediate logout everywhere)', async () => {
    const email = `me-del-${randomUUID().slice(0, 12)}@example.com`;
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
    const login = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code },
    });
    const { accessToken, refreshToken, user } = login.json();

    const del = await app.inject({
      method: 'DELETE',
      url: '/v1/me',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(del.statusCode).toBe(200);
    expect(del.json().ok).toBe(true);

    const row = await handle.pg`SELECT deleted_at FROM users WHERE id = ${user.id}`;
    expect(row[0]?.deleted_at).toBeTruthy();

    // The refresh token issued before deletion is dead — immediate logout everywhere.
    // (already-used tokens read as reuse per SPEC §4, which is the correct posture here.)
    const refreshAfterDelete = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken },
    });
    expect(refreshAfterDelete.statusCode).toBe(403);
    expect(refreshAfterDelete.json().error.code).toBe('auth/refresh_reused');

    const tokens = await handle.pg`SELECT used FROM refresh_tokens WHERE user_id = ${user.id}`;
    expect(tokens.length).toBeGreaterThan(0);
    expect(tokens.every((r) => r.used === true)).toBe(true);
  });

  it('GET /me/export: 501 service/unavailable (no job queue yet)', async () => {
    const u = await makeUser();
    const res = await app.inject({ method: 'GET', url: '/v1/me/export', headers: u.headers });
    expect(res.statusCode).toBe(501);
    expect(res.json().error.code).toBe('service/unavailable');
  });

  it('unauthenticated → 401 auth/missing on every /me route', async () => {
    for (const req of [
      { method: 'GET' as const, url: '/v1/me' },
      { method: 'GET' as const, url: '/v1/me/map' },
      { method: 'DELETE' as const, url: '/v1/me' },
    ]) {
      const res = await app.inject(req);
      expect(res.statusCode).toBe(401);
    }
  });
});
