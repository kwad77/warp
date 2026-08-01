// SPEC §4 — Sign in with Apple / Google: verify the platform ID token (issuer + audience
// + signature via the provider's JWKS), link by stable provider subject.
import { type JWTVerifyGetKey, createRemoteJWKSet, jwtVerify } from 'jose';
import { AppError } from '../errors.js';

export interface OidcVerifier {
  /** Verifies signature + issuer + audience + expiry; returns the stable provider subject. */
  verify(idToken: string): Promise<{ sub: string }>;
}

/** Exported for tests: takes an injected JWKS resolver instead of a hardcoded remote URL. */
export function createOidcVerifier(
  jwks: JWTVerifyGetKey,
  issuer: string | string[],
  audience: string,
): OidcVerifier {
  return {
    async verify(idToken) {
      let sub: unknown;
      try {
        const result = await jwtVerify(idToken, jwks, { issuer, audience });
        sub = result.payload.sub;
      } catch {
        throw new AppError('auth/invalid', 'Invalid or expired identity token');
      }
      if (typeof sub !== 'string' || sub.length === 0) {
        throw new AppError('auth/invalid', 'Invalid or expired identity token');
      }
      return { sub };
    },
  };
}

const APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys';
const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';

export function createAppleVerifier(clientId: string): OidcVerifier {
  return createOidcVerifier(
    createRemoteJWKSet(new URL(APPLE_JWKS_URL)),
    'https://appleid.apple.com',
    clientId,
  );
}

export function createGoogleVerifier(clientId: string): OidcVerifier {
  return createOidcVerifier(
    createRemoteJWKSet(new URL(GOOGLE_JWKS_URL)),
    ['https://accounts.google.com', 'accounts.google.com'],
    clientId,
  );
}
