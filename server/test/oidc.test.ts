// SPEC §4 — Apple/Google ID token verification. Pure: no network, no DB. Uses a locally
// generated keypair + createLocalJWKSet so this never depends on Apple/Google's real
// endpoints being reachable in CI.
import { SignJWT, createLocalJWKSet, exportJWK, generateKeyPair } from 'jose';
import { beforeAll, describe, expect, it } from 'vitest';
import { createOidcVerifier } from '../src/auth/oidc.js';

const ISSUER = 'https://issuer.example';
const AUDIENCE = 'test-client-id';

describe('createOidcVerifier (SPEC §4)', () => {
  let jwks: ReturnType<typeof createLocalJWKSet>;
  let privateKey: CryptoKey;

  async function sign(claims: Record<string, unknown>, opts?: { expSecondsFromNow?: number }) {
    const jwt = new SignJWT(claims)
      .setProtectedHeader({ alg: 'RS256', kid: 'test-key' })
      .setIssuedAt()
      .setExpirationTime(Math.floor(Date.now() / 1000) + (opts?.expSecondsFromNow ?? 3600));
    return jwt.sign(privateKey);
  }

  beforeAll(async () => {
    const { publicKey, privateKey: priv } = await generateKeyPair('RS256');
    privateKey = priv;
    const jwk = await exportJWK(publicKey);
    jwks = createLocalJWKSet({ keys: [{ ...jwk, kid: 'test-key', alg: 'RS256' }] });
  });

  it('accepts a validly signed token with matching issuer/audience', async () => {
    const verifier = createOidcVerifier(jwks, ISSUER, AUDIENCE);
    const token = await sign({ iss: ISSUER, aud: AUDIENCE, sub: 'provider-subject-1' });

    const result = await verifier.verify(token);

    expect(result.sub).toBe('provider-subject-1');
  });

  it('rejects a token with the wrong audience', async () => {
    const verifier = createOidcVerifier(jwks, ISSUER, AUDIENCE);
    const token = await sign({ iss: ISSUER, aud: 'someone-elses-client-id', sub: 'x' });

    await expect(verifier.verify(token)).rejects.toMatchObject({ code: 'auth/invalid' });
  });

  it('rejects a token with the wrong issuer', async () => {
    const verifier = createOidcVerifier(jwks, ISSUER, AUDIENCE);
    const token = await sign({
      iss: 'https://not-the-real-issuer.example',
      aud: AUDIENCE,
      sub: 'x',
    });

    await expect(verifier.verify(token)).rejects.toMatchObject({ code: 'auth/invalid' });
  });

  it('rejects an expired token', async () => {
    const verifier = createOidcVerifier(jwks, ISSUER, AUDIENCE);
    const token = await sign({ iss: ISSUER, aud: AUDIENCE, sub: 'x' }, { expSecondsFromNow: -60 });

    await expect(verifier.verify(token)).rejects.toMatchObject({ code: 'auth/invalid' });
  });

  it('rejects a token missing sub', async () => {
    const verifier = createOidcVerifier(jwks, ISSUER, AUDIENCE);
    const token = await sign({ iss: ISSUER, aud: AUDIENCE });

    await expect(verifier.verify(token)).rejects.toMatchObject({ code: 'auth/invalid' });
  });

  it('accepts an array of issuers (Google issues under two forms)', async () => {
    const verifier = createOidcVerifier(jwks, ['https://a.example', ISSUER], AUDIENCE);
    const token = await sign({ iss: ISSUER, aud: AUDIENCE, sub: 'x' });

    await expect(verifier.verify(token)).resolves.toMatchObject({ sub: 'x' });
  });

  it('rejects a malformed token string outright', async () => {
    const verifier = createOidcVerifier(jwks, ISSUER, AUDIENCE);

    await expect(verifier.verify('not-a-jwt')).rejects.toMatchObject({ code: 'auth/invalid' });
  });
});
