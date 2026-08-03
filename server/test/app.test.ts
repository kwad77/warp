// Route tests via app.inject() — no network, no DB required (SPEC §10).
import { afterAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { devTextModerationProvider } from '../src/moderation/text_provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const config = loadConfig({
  JWT_SECRET: 'test-secret-that-is-at-least-32-chars!!',
  NODE_ENV: 'test',
});
const app = buildApp({
  config,
  dbHandle: null,
  storage: createR2Storage(config),
  moderation: devModerationProvider(() => {}),
  textModeration: devTextModerationProvider(),
  oidcVerifiers: { apple: null, google: null },
});
afterAll(() => app.close());

describe('health', () => {
  it('healthz is 200 without a DB', async () => {
    const res = await app.inject({ method: 'GET', url: '/healthz' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ ok: true });
  });
  it('readyz is 503 without a DB, with the SPEC envelope', async () => {
    const res = await app.inject({ method: 'GET', url: '/readyz' });
    expect(res.statusCode).toBe(503);
    expect(res.json().error.code).toBe('service/unavailable');
  });
});

describe('error envelope behavior', () => {
  it('unknown route → 404 resource/not_found', async () => {
    const res = await app.inject({ method: 'GET', url: '/v1/nope' });
    expect(res.statusCode).toBe(404);
    expect(res.json().error.code).toBe('resource/not_found');
  });
  it('invalid email → 400 request/invalid with issues', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/request',
      payload: { email: 'not-an-email' },
    });
    expect(res.statusCode).toBe(400);
    const body = res.json();
    expect(body.error.code).toBe('request/invalid');
    expect(body.error.details.issues[0].path).toBe('email');
  });
  it('malformed JSON → 400 request/invalid', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/request',
      headers: { 'content-type': 'application/json' },
      payload: '{nope',
    });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('request/invalid');
  });
});

describe('auth surface', () => {
  it('apple/google are 501 when APPLE_CLIENT_ID/GOOGLE_CLIENT_ID are unset', async () => {
    for (const url of ['/v1/auth/apple', '/v1/auth/google']) {
      const res = await app.inject({ method: 'POST', url, payload: { idToken: 'x' } });
      expect(res.statusCode).toBe(501);
      expect(res.json().error.code).toBe('service/unavailable');
    }
  });
  it('protected route without a token → 401 auth/missing', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/devices',
      payload: { platform: 'ios' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('auth/missing');
  });
  it('valid-shape email request without a DB → 503', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/request',
      payload: { email: 'someone@example.com' },
    });
    expect(res.statusCode).toBe(503);
    expect(res.json().error.code).toBe('service/unavailable');
  });
});
