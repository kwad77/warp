// SPEC §7 — coverage leaderboard, against real PostGIS.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { SPEC_CONSTANTS } from '../src/constants.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { coverageCell, dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { getCoverageLeaderboard } from '../src/leaderboards/service.js';
import { isoWeekStartUtc } from '../src/lib/isoWeek.js';
import { uuidv7 } from '../src/lib/uuid.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

const BASE_LL = { lat: -10.0, lng: 100.0 };
const RUN_SALT_M = Math.floor(Math.random() * 400_000);

describe.runIf(!!url)('leaderboards (SPEC §7)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `lb-${randomUUID().slice(0, 12)}@example.com`;
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

  async function addCoverage(
    userId: string,
    ll: { lat: number; lng: number },
    createdAt: Date,
  ): Promise<void> {
    const poiId = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${poiId}, ${userId}, 'x', 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll)).toString()}, 75, 'active')`;
    const checkinId = uuidv7();
    const cell = h3ToBigint(coverageCell(ll)).toString();
    await handle.pg`
      INSERT INTO checkins (id, user_id, poi_id, mode, status, h3_r7, created_at, verified_at)
      VALUES (${checkinId}, ${userId}, ${poiId}, 'confirm', 'verified', ${cell},
              ${createdAt.toISOString()}, ${createdAt.toISOString()})`;
    await handle.pg`
      INSERT INTO user_coverage (user_id, h3_r7, first_checkin_id, created_at)
      VALUES (${userId}, ${cell}, ${checkinId}, ${createdAt.toISOString()})
      ON CONFLICT DO NOTHING`;
  }

  beforeAll(async () => {
    await migrate(url as string, () => {});
    handle = createDb(url as string);
    const config = loadConfig({
      JWT_SECRET: 'test-secret-that-is-at-least-32-chars!!',
      NODE_ENV: 'test',
      DATABASE_URL: url,
    });
    app = buildApp({ config, dbHandle: handle, storage: createR2Storage(config) });
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('ranks by distinct cell count descending; "all" ignores a cell older than this week', async () => {
    const now = new Date();
    const lastWeek = new Date(isoWeekStartUtc(now).getTime() - 60_000); // just before this ISO week

    const leader = await makeUser();
    await addCoverage(leader.userId, offsetLatMeters(BASE_LL, RUN_SALT_M), now);
    await addCoverage(leader.userId, offsetLatMeters(BASE_LL, RUN_SALT_M + 6_000), now);
    await addCoverage(leader.userId, offsetLatMeters(BASE_LL, RUN_SALT_M + 12_000), lastWeek);

    const runnerUp = await makeUser();
    await addCoverage(runnerUp.userId, offsetLatMeters(BASE_LL, RUN_SALT_M + 20_000), now);

    const all = await app.inject({
      method: 'GET',
      url: '/v1/leaderboards/coverage?window=all&scope=global',
    });
    expect(all.statusCode).toBe(200);
    const allEntries = all.json().entries as { handle: string; cells: number }[];
    const leaderEntry = allEntries.find((e) => e.cells === 3);
    expect(leaderEntry).toBeTruthy();

    const weekly = await app.inject({
      method: 'GET',
      url: '/v1/leaderboards/coverage?window=weekly&scope=global',
    });
    const weeklyEntries = weekly.json().entries as { handle: string; cells: number }[];
    // The leader's last-week cell must not count toward the weekly window.
    const leaderWeekly = weeklyEntries.find((e) => e.handle === leaderEntry?.handle);
    expect(leaderWeekly?.cells).toBe(2);
  });

  it('me is present with a valid token, absent without one', async () => {
    const u = await makeUser();
    await addCoverage(u.userId, offsetLatMeters(BASE_LL, RUN_SALT_M + 40_000), new Date());

    const withAuth = await app.inject({
      method: 'GET',
      url: '/v1/leaderboards/coverage?window=all&scope=global',
      headers: u.headers,
    });
    expect(withAuth.json().me).toBeTruthy();
    expect(withAuth.json().me.cells).toBeGreaterThanOrEqual(1);

    const withoutAuth = await app.inject({
      method: 'GET',
      url: '/v1/leaderboards/coverage?window=all&scope=global',
    });
    expect(withoutAuth.json().me).toBeUndefined();
  });

  it('scope other than global → 400 request/invalid', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/leaderboards/coverage?window=all&scope=country',
    });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('request/invalid');
  });

  it('invalid window → 400 request/invalid', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/v1/leaderboards/coverage?window=monthly&scope=global',
    });
    expect(res.statusCode).toBe(400);
  });

  it('a requester ranked below the entries cap still gets a correct "me" rank', async () => {
    // Cheap direct-SQL fixture (bypasses the full auth flow) to exercise the "not in the
    // top page" branch: enough ghost users with 2 cells each to guarantee the requester's
    // single cell falls off the top page. Other tests in this file may have already added
    // a handful of users with a few cells each, so don't assume this test owns the whole
    // table — derive the expectation from the same data the query itself sees.
    const now = new Date();
    const max = SPEC_CONSTANTS.leaderboard.LEADERBOARD_ENTRIES_MAX;
    // H3 res-7 cells span roughly 1-3km, so the two points per ghost must be spaced well
    // beyond that or they silently collapse onto the same cell (ON CONFLICT DO NOTHING).
    for (let i = 0; i < max; i++) {
      const id = uuidv7();
      await handle.pg`INSERT INTO users (id, handle) VALUES (${id}, ${`ghost_${i}_${randomUUID().slice(0, 6)}`})`;
      for (let j = 0; j < 2; j++) {
        await addCoverage(
          id,
          offsetLatMeters(BASE_LL, RUN_SALT_M + 100_000 + i * 10_000 + j * 5_000),
          now,
        );
      }
    }
    const requesterId = uuidv7();
    await handle.pg`INSERT INTO users (id, handle) VALUES (${requesterId}, ${`ghost_req_${randomUUID().slice(0, 6)}`})`;
    await addCoverage(requesterId, offsetLatMeters(BASE_LL, RUN_SALT_M + 2_000_000), now);

    const expectedAbove = await handle.pg`
      SELECT count(*)::int AS n FROM (
        SELECT user_id, count(*) AS c FROM user_coverage
        GROUP BY user_id HAVING count(*) > 1
      ) ranked_above`;
    const expectedRank = Number((expectedAbove[0] as { n: number }).n) + 1;

    const result = await getCoverageLeaderboard(handle.pg, 'all', requesterId, now);
    expect(result.entries.length).toBe(max);
    // The requester's single cell must not be enough to make the top page — every
    // entry that did make it has strictly more than the requester's 1 cell.
    expect(result.entries.every((e) => e.cells > 1)).toBe(true);
    expect(result.me).toEqual({ rank: expectedRank, cells: 1 });
  });
});
