// SPEC §5.6 — trust events fold into users.trust_score at insert time, clamped [0, 100].
import { sql } from 'drizzle-orm';
import { SPEC_CONSTANTS } from '../constants.js';
import type { Db } from '../db/client.js';
import { trustEvents, users } from '../db/schema.js';
import { uuidv7 } from '../lib/uuid.js';

const T = SPEC_CONSTANTS.trust;

export type TrustEventType =
  | 'integrity_fail'
  | 'velocity_violation'
  | 'report_upheld'
  | 'people_photo_upheld'
  | 'clean_30d';

export const TRUST_DELTAS: Record<TrustEventType, number> = {
  integrity_fail: T.D_INTEGRITY_FAIL,
  velocity_violation: T.D_VELOCITY_VIOLATION,
  report_upheld: T.D_REPORT_UPHELD,
  people_photo_upheld: T.D_PEOPLE_PHOTO_UPHELD,
  clean_30d: T.D_CLEAN_30D,
};

export async function recordTrustEvent(
  db: Db,
  userId: string,
  type: TrustEventType,
  metadata: Record<string, unknown> | null,
  now: Date,
): Promise<void> {
  const delta = TRUST_DELTAS[type];
  await db.insert(trustEvents).values({
    id: uuidv7(now.getTime()),
    userId,
    type,
    delta,
    metadata,
  });
  await db
    .update(users)
    .set({
      trustScore: sql`LEAST(${T.MAX}, GREATEST(${T.MIN}, ${users.trustScore} + ${delta}))`,
    })
    .where(sql`${users.id} = ${userId}`);
}
