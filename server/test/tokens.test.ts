import { describe, expect, it } from 'vitest';
import {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
} from '../src/auth/tokens.js';
import { AppError } from '../src/errors.js';

const SECRET = 'test-secret-that-is-at-least-32-chars!!';
const USER = '01936b2a-0000-7000-8000-000000000001';

describe('tokens (SPEC §4)', () => {
  it('access token round-trips', async () => {
    const token = await signAccessToken(SECRET, USER);
    const claims = await verifyAccessToken(SECRET, token);
    expect(claims.sub).toBe(USER);
  });

  it('refresh token round-trips with jti and fam', async () => {
    const token = await signRefreshToken(SECRET, USER, 'jti-1', 'fam-1');
    const claims = await verifyRefreshToken(SECRET, token);
    expect(claims).toMatchObject({ sub: USER, jti: 'jti-1', fam: 'fam-1' });
  });

  it('a refresh token is not a valid access token', async () => {
    const token = await signRefreshToken(SECRET, USER, 'jti-1', 'fam-1');
    await expect(verifyAccessToken(SECRET, token)).rejects.toMatchObject({
      code: 'auth/invalid',
    });
  });

  it('wrong secret → auth/invalid', async () => {
    const token = await signAccessToken(SECRET, USER);
    await expect(verifyAccessToken(`${SECRET}x`, token)).rejects.toBeInstanceOf(AppError);
  });

  it('garbage → auth/invalid', async () => {
    await expect(verifyAccessToken(SECRET, 'not-a-jwt')).rejects.toMatchObject({
      code: 'auth/invalid',
    });
  });
});
