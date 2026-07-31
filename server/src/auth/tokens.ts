// SPEC §4 — access/refresh JWTs. HS256; refresh tokens rotate with reuse detection.
import { SignJWT, errors as joseErrors, jwtVerify } from 'jose';
import { SPEC_CONSTANTS } from '../constants.js';
import { AppError } from '../errors.js';

const A = SPEC_CONSTANTS.auth;
const encoder = new TextEncoder();

export interface AccessClaims {
  sub: string;
  typ: 'access';
}

export interface RefreshClaims {
  sub: string;
  typ: 'refresh';
  jti: string;
  fam: string;
}

function key(secret: string): Uint8Array {
  return encoder.encode(secret);
}

export async function signAccessToken(secret: string, userId: string): Promise<string> {
  return new SignJWT({ typ: 'access' })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${A.ACCESS_TTL_S}s`)
    .sign(key(secret));
}

export async function signRefreshToken(
  secret: string,
  userId: string,
  jti: string,
  fam: string,
): Promise<string> {
  return new SignJWT({ typ: 'refresh', fam })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(userId)
    .setJti(jti)
    .setIssuedAt()
    .setExpirationTime(`${A.REFRESH_TTL_S}s`)
    .sign(key(secret));
}

async function verify(secret: string, token: string): Promise<Record<string, unknown>> {
  try {
    const { payload } = await jwtVerify(token, key(secret), { algorithms: ['HS256'] });
    return payload;
  } catch (err) {
    if (err instanceof joseErrors.JWTExpired) {
      throw new AppError('auth/expired', 'Token has expired');
    }
    throw new AppError('auth/invalid', 'Token is invalid');
  }
}

export async function verifyAccessToken(secret: string, token: string): Promise<AccessClaims> {
  const p = await verify(secret, token);
  if (p.typ !== 'access' || typeof p.sub !== 'string') {
    throw new AppError('auth/invalid', 'Not an access token');
  }
  return { sub: p.sub, typ: 'access' };
}

export async function verifyRefreshToken(secret: string, token: string): Promise<RefreshClaims> {
  const p = await verify(secret, token);
  if (
    p.typ !== 'refresh' ||
    typeof p.sub !== 'string' ||
    typeof p.jti !== 'string' ||
    typeof p.fam !== 'string'
  ) {
    throw new AppError('auth/invalid', 'Not a refresh token');
  }
  return { sub: p.sub, typ: 'refresh', jti: p.jti, fam: p.fam };
}
