// SPEC §4 — Sign in with Apple/Google against real PostGIS, with a locally-keyed
// OidcVerifier (not the real Apple/Google JWKS endpoints — createOidcVerifier itself is
// covered without a DB in oidc.test.ts).
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { SignJWT, createLocalJWKSet, exportJWK, generateKeyPair } from 'jose';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { createOidcVerifier } from '../src/auth/oidc.js';
import { loginWithProvider } from '../src/auth/service.js';
import { loadConfig } from '../src/config.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import { devTextModerationProvider } from '../src/moderation/text_provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;
const ISSUER = 'https://issuer.example';
const AUDIENCE = 'test-client-id';

describe.runIf(!!url)('Sign in with Apple/Google (SPEC §4)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;
  let privateKey: CryptoKey;

  async function signToken(sub: string) {
    return new SignJWT({ iss: ISSUER, aud: AUDIENCE, sub })
      .setProtectedHeader({ alg: 'RS256', kid: 'test-key' })
      .setIssuedAt()
      .setExpirationTime(Math.floor(Date.now() / 1000) + 3600)
      .sign(privateKey);
  }

  beforeAll(async () => {
    await migrate(url as string, () => {});
    handle = createDb(url as string);
    const { publicKey, privateKey: priv } = await generateKeyPair('RS256');
    privateKey = priv;
    const jwk = await exportJWK(publicKey);
    const jwks = createLocalJWKSet({ keys: [{ ...jwk, kid: 'test-key', alg: 'RS256' }] });
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
      textModeration: devTextModerationProvider(),
      oidcVerifiers: {
        apple: createOidcVerifier(jwks, ISSUER, AUDIENCE),
        google: createOidcVerifier(jwks, ISSUER, AUDIENCE),
      },
    });
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('POST /auth/apple with a fresh subject creates a new account', async () => {
    const sub = `apple-${randomUUID()}`;
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/apple',
      payload: { idToken: await signToken(sub) },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.accessToken).toBeTypeOf('string');
    expect(body.refreshToken).toBeTypeOf('string');
    expect(body.user.handle).toMatch(/^explorer_/);
  });

  it('POST /auth/google logging in twice with the same subject returns the same user', async () => {
    const sub = `google-${randomUUID()}`;
    const first = await app.inject({
      method: 'POST',
      url: '/v1/auth/google',
      payload: { idToken: await signToken(sub) },
    });
    const second = await app.inject({
      method: 'POST',
      url: '/v1/auth/google',
      payload: { idToken: await signToken(sub) },
    });

    expect(first.json().user.id).toBe(second.json().user.id);
  });

  it('an invalid idToken (bad signature/issuer) → 401 auth/invalid', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/apple',
      payload: { idToken: 'not-a-real-token' },
    });

    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('auth/invalid');
  });

  it('loginWithProvider on a soft-deleted account → account/suspended', async () => {
    const sub = `apple-${randomUUID()}`;
    const first = await loginWithProvider(
      handle.db,
      'test-secret-that-is-at-least-32-chars!!',
      'apple',
      sub,
      new Date(),
    );
    await handle.pg`UPDATE users SET deleted_at = now() WHERE id = ${first.user.id}`;

    await expect(
      loginWithProvider(
        handle.db,
        'test-secret-that-is-at-least-32-chars!!',
        'apple',
        sub,
        new Date(),
      ),
    ).rejects.toMatchObject({ code: 'account/suspended' });
  });
});
