// SPEC §7 — photo voting and reporting. Small, table-driven CRUD.
import { SPEC_CONSTANTS } from '../constants.js';
import type { Db, Pg } from '../db/client.js';
import { AppError } from '../errors.js';
import { uuidv7 } from '../lib/uuid.js';

const RATE = SPEC_CONSTANTS.rate;

export async function voteOnPhoto(
  pg: Pg,
  userId: string,
  photoId: string,
  value: 0 | 1,
): Promise<{ voteScore: number }> {
  const photoRows =
    await pg`SELECT id FROM photos WHERE id = ${photoId} AND moderation = 'approved'`;
  if (photoRows.length === 0) {
    throw new AppError('resource/not_found', 'No such photo');
  }

  await pg.begin(async (tx) => {
    if (value === 0) {
      await tx`DELETE FROM votes WHERE user_id = ${userId} AND photo_id = ${photoId}`;
    } else {
      await tx`
        INSERT INTO votes (user_id, photo_id, value)
        VALUES (${userId}, ${photoId}, 1)
        ON CONFLICT (user_id, photo_id) DO UPDATE SET value = 1`;
    }
    await tx`
      UPDATE photos SET vote_score = (
        SELECT count(*)::int FROM votes WHERE photo_id = ${photoId}
      ) WHERE id = ${photoId}`;
  });

  const scoreRows = await pg`SELECT vote_score FROM photos WHERE id = ${photoId}`;
  const voteScore = Number((scoreRows[0] as { vote_score: number } | undefined)?.vote_score ?? 0);
  return { voteScore };
}

export type ReportTargetType = 'poi' | 'photo';
export type ReportReason = 'people' | 'unsafe' | 'wrong_location' | 'duplicate' | 'other';

async function targetExists(
  pg: Pg,
  targetType: ReportTargetType,
  targetId: string,
): Promise<boolean> {
  const rows =
    targetType === 'poi'
      ? await pg`SELECT 1 FROM pois WHERE id = ${targetId} AND status <> 'removed'`
      : await pg`SELECT 1 FROM photos WHERE id = ${targetId}`;
  return rows.length > 0;
}

export async function createReport(
  db: Db,
  pg: Pg,
  reporterId: string,
  targetType: ReportTargetType,
  targetId: string,
  reason: ReportReason,
  note: string | undefined,
  now: Date,
): Promise<void> {
  if (!(await targetExists(pg, targetType, targetId))) {
    throw new AppError('resource/not_found', 'No such target');
  }
  const dayAgo = new Date(now.getTime() - 86_400_000);
  const countRows = await pg`
    SELECT count(*)::int AS n FROM reports
    WHERE reporter_id = ${reporterId} AND created_at > ${dayAgo.toISOString()}`;
  const recent = Number((countRows[0] as { n: number } | undefined)?.n ?? 0);
  if (recent >= RATE.REPORT_CREATE_PER_DAY) {
    throw new AppError('rate/limited', 'Too many reports today', { retryAfterS: 86_400 });
  }
  await pg`
    INSERT INTO reports (id, reporter_id, target_type, target_id, reason, note)
    VALUES (${uuidv7(now.getTime())}, ${reporterId}, ${targetType}, ${targetId}, ${reason}, ${note ?? null})`;
}
