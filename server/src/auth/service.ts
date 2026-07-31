// SPEC §4 — email code flow and refresh rotation with reuse detection.
import { createHash, randomBytes, randomInt } from 'node:crypto';
import { and, count, eq, gt, sql } from 'drizzle-orm';
import { SPEC_CONSTANTS } from '../constants.js';
import type { Db } from '../db/client.js';
import { emailLoginCodes, refreshTokens, users } from '../db/schema.js';
import { AppError } from '../errors.js';
import { uuidv7 } from '../lib/uuid.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from './tokens.js';

const A = SPEC_CONSTANTS.auth;
const R = SPEC_CONSTANTS.rate;

export interface MailSender {
  sendLoginCode(email: string, code: string): Promise<void>;
}

export interface PublicUser {
  id: string;
  handle: string;
  createdAt: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

function sha256(input: string): string {
  return createHash('sha256').update(input).digest('hex');
}

function newHandle(): string {
  // Crockford-ish base32, no vowels that make words.
  const alphabet = '0123456789bcdfghjkmnpqrstvwxz';
  const suffix = Array.from(randomBytes(6), (b) => alphabet[b % alphabet.length]).join('');
  return `explorer_${suffix}`;
}

export async function requestEmailCode(
  db: Db,
  mail: MailSender,
  email: string,
  now: Date,
): Promise<void> {
  const windowStart = new Date(now.getTime() - R.AUTH_EMAIL_REQUEST_WINDOW_S * 1000);
  const [recent] = await db
    .select({ n: count() })
    .from(emailLoginCodes)
    .where(and(eq(emailLoginCodes.email, email), gt(emailLoginCodes.createdAt, windowStart)));
  if ((recent?.n ?? 0) >= R.AUTH_EMAIL_REQUEST_MAX) {
    throw new AppError('rate/limited', 'Too many code requests', {
      retryAfterS: R.AUTH_EMAIL_REQUEST_WINDOW_S,
    });
  }
  const code = randomInt(0, 10 ** A.EMAIL_CODE_LENGTH)
    .toString()
    .padStart(A.EMAIL_CODE_LENGTH, '0');
  await db.insert(emailLoginCodes).values({
    email,
    codeHash: sha256(code),
    expiresAt: new Date(now.getTime() + A.EMAIL_CODE_TTL_S * 1000),
  });
  await mail.sendLoginCode(email, code);
}

async function issueTokens(db: Db, secret: string, userId: string, now: Date): Promise<TokenPair> {
  const jti = uuidv7(now.getTime());
  const fam = uuidv7(now.getTime());
  await db.insert(refreshTokens).values({
    jti,
    fam,
    userId,
    expiresAt: new Date(now.getTime() + A.REFRESH_TTL_S * 1000),
  });
  return {
    accessToken: await signAccessToken(secret, userId),
    refreshToken: await signRefreshToken(secret, userId, jti, fam),
  };
}

export async function verifyEmailCode(
  db: Db,
  secret: string,
  email: string,
  code: string,
  now: Date,
): Promise<{ tokens: TokenPair; user: PublicUser }> {
  const updated = await db
    .update(emailLoginCodes)
    .set({ used: true })
    .where(
      and(
        eq(emailLoginCodes.email, email),
        eq(emailLoginCodes.codeHash, sha256(code)),
        eq(emailLoginCodes.used, false),
        gt(emailLoginCodes.expiresAt, now),
      ),
    )
    .returning({ email: emailLoginCodes.email });
  if (updated.length === 0) {
    throw new AppError('auth/invalid', 'Invalid or expired code');
  }

  let user = (await db.select().from(users).where(eq(users.email, email)))[0];
  if (!user) {
    for (let attempt = 0; attempt < 3 && !user; attempt++) {
      try {
        user = (
          await db
            .insert(users)
            .values({ id: uuidv7(now.getTime()), handle: newHandle(), email })
            .returning()
        )[0];
      } catch {
        // handle collision — retry with a new one; anything else recurs and surfaces below.
      }
    }
    if (!user) throw new AppError('internal/error', 'Could not create account');
  }
  if (user.deletedAt !== null) {
    throw new AppError('account/suspended', 'Account is deactivated');
  }
  return {
    tokens: await issueTokens(db, secret, user.id, now),
    user: { id: user.id, handle: user.handle, createdAt: user.createdAt.toISOString() },
  };
}

export async function rotateRefreshToken(
  db: Db,
  secret: string,
  token: string,
  now: Date,
): Promise<TokenPair> {
  const claims = await verifyRefreshToken(secret, token);
  const row = (await db.select().from(refreshTokens).where(eq(refreshTokens.jti, claims.jti)))[0];
  if (!row || row.expiresAt <= now) {
    throw new AppError('auth/invalid', 'Refresh token is not recognized');
  }
  if (row.used) {
    // Reuse ⇒ the family is compromised: revoke every token in it. SPEC §4.
    await db.update(refreshTokens).set({ used: true }).where(eq(refreshTokens.fam, row.fam));
    throw new AppError('auth/refresh_reused', 'Refresh token reuse detected');
  }
  const claimed = await db
    .update(refreshTokens)
    .set({ used: true })
    .where(and(eq(refreshTokens.jti, claims.jti), eq(refreshTokens.used, false)))
    .returning({ jti: refreshTokens.jti });
  if (claimed.length === 0) {
    // Lost a concurrent race: treat as reuse.
    await db.update(refreshTokens).set({ used: true }).where(eq(refreshTokens.fam, row.fam));
    throw new AppError('auth/refresh_reused', 'Refresh token reuse detected');
  }
  const jti = uuidv7(now.getTime());
  await db.insert(refreshTokens).values({
    jti,
    fam: row.fam,
    userId: row.userId,
    expiresAt: new Date(now.getTime() + A.REFRESH_TTL_S * 1000),
  });
  return {
    accessToken: await signAccessToken(secret, row.userId),
    refreshToken: await signRefreshToken(secret, row.userId, jti, row.fam),
  };
}

/** Dev/test mail transport: SPEC §4 — dev logs the code instead of sending mail. */
export function devMailSender(log: (msg: string) => void): MailSender {
  return {
    async sendLoginCode(email, code) {
      log(`[dev-mail] login code for ${sha256(email).slice(0, 8)}…: ${code}`);
    },
  };
}

/** Purge helper for tests/workers. */
export async function _deleteExpiredCodes(db: Db, now: Date): Promise<void> {
  await db.delete(emailLoginCodes).where(sql`${emailLoginCodes.expiresAt} <= ${now}`);
}
