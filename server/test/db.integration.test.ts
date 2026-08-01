// Full auth flow against real PostGIS. Runs when TEST_DATABASE_URL is set (CI always sets
// it; locally: docker compose up -d db && npm run db:migrate). SPEC §4, §10.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;

describe.runIf(!!url)('auth flow (real database)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;
  const email = `it-${randomUUID().slice(0, 8)}@example.com`;

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

  // Codes are stored hashed, so tests capture one via a stub mailer at the service layer.
  async function latestCodeFor(addr: string): Promise<string> {
    const { requestEmailCode } = await import('../src/auth/service.js');
    let captured = '';
    const stub = {
      sendLoginCode: async (_e: string, c: string) => {
        captured = c;
      },
    };
    await requestEmailCode(handle.db, stub, addr, new Date());
    return captured;
  }

  it('readyz is 200 with a live DB', async () => {
    const res = await app.inject({ method: 'GET', url: '/readyz' });
    expect(res.statusCode).toBe(200);
  });

  it('email verify issues tokens and creates a user; code is single-use', async () => {
    const code = await latestCodeFor(email);
    const ok = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code },
    });
    expect(ok.statusCode).toBe(200);
    const body = ok.json();
    expect(body.user.handle).toMatch(/^explorer_/);
    expect(body.accessToken).toBeTruthy();

    const reuse = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code },
    });
    expect(reuse.statusCode).toBe(401);
  });

  it('wrong code → 401 auth/invalid', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code: '000000' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('auth/invalid');
  });

  it('refresh rotates; reusing the old refresh token revokes the family', async () => {
    const code = await latestCodeFor(email);
    const login = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code },
    });
    const first = login.json().refreshToken as string;

    const rotated = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first },
    });
    expect(rotated.statusCode).toBe(200);
    const second = rotated.json().refreshToken as string;
    expect(second).not.toBe(first);

    // Replay of the first token → reuse detected.
    const replay = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first },
    });
    expect(replay.statusCode).toBe(403);
    expect(replay.json().error.code).toBe('auth/refresh_reused');

    // The whole family is dead: the rotated token no longer works either.
    const afterRevoke = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: second },
    });
    expect(afterRevoke.statusCode).toBe(403);
  });

  it('rate limit: 6th code request inside the window → 429', async () => {
    const addr = `rl-${randomUUID().slice(0, 8)}@example.com`;
    for (let i = 0; i < 5; i++) {
      const res = await app.inject({
        method: 'POST',
        url: '/v1/auth/email/request',
        payload: { email: addr },
      });
      expect(res.statusCode).toBe(200);
    }
    const sixth = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/request',
      payload: { email: addr },
    });
    expect(sixth.statusCode).toBe(429);
    expect(sixth.json().error.code).toBe('rate/limited');
  });

  it('device registration with a real access token → 201', async () => {
    const addr = `dev-${randomUUID().slice(0, 8)}@example.com`;
    const code = await latestCodeFor(addr);
    const login = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email: addr, code },
    });
    expect(login.statusCode).toBe(200);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/devices',
      headers: { authorization: `Bearer ${login.json().accessToken}` },
      payload: { platform: 'android', model: 'Pixel 8' },
    });
    expect(res.statusCode).toBe(201);
    expect(res.json().deviceId).toMatch(/^[0-9a-f-]{36}$/);
  });

  it('PostGIS is actually installed (geography type works)', async () => {
    const rows = await handle.pg`
      SELECT ST_Distance(
        'SRID=4326;POINT(-9.13 38.7139)'::geography,
        'SRID=4326;POINT(-8.6291 41.1579)'::geography) AS d`;
    const d = Number(rows[0]?.d);
    expect(d).toBeGreaterThan(265_000);
    expect(d).toBeLessThan(285_000);
  });
});
