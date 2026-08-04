// SPEC §16 (M2) — badge taxonomy + awarding. Called inside the same transaction as the
// verified check-in's user_coverage insert / checkin_count increment (checkins/service.ts)
// so a rolled-back check-in never awards a badge; `pending → verified` transitions award
// at that time instead, same as those two side effects.
import { count, eq } from 'drizzle-orm';
import { SPEC_CONSTANTS } from '../constants.js';
import type { Db } from '../db/client.js';
import { badges, userCoverage } from '../db/schema.js';

export type BadgeKey =
  | 'first_in_region'
  | 'poi_milestone_10'
  | 'poi_milestone_50'
  | 'poi_milestone_100';

const MILESTONES = SPEC_CONSTANTS.badges.POI_CHECKIN_MILESTONES;

async function award(tx: Db, userId: string, badgeKey: BadgeKey): Promise<void> {
  await tx.insert(badges).values({ userId, badgeKey }).onConflictDoNothing();
}

/**
 * `first_in_region`: awarded once, ever, if this call's `h3R7` cell now has exactly one
 * `user_coverage` row (across ALL users) — i.e. this check-in (or an earlier one that
 * already inserted the row; `ON CONFLICT DO NOTHING` upstream makes re-checks harmless,
 * see SPEC §16) is the first anyone has recorded there.
 */
async function awardFirstInRegion(tx: Db, userId: string, h3R7: bigint): Promise<void> {
  const rows = await tx
    .select({ n: count() })
    .from(userCoverage)
    .where(eq(userCoverage.h3R7, h3R7));
  if ((rows[0]?.n ?? 0) === 1) {
    await award(tx, userId, 'first_in_region');
  }
}

/**
 * `poi_milestone_{10,50,100}`: awarded to [poiCreatorId] for every milestone at or below
 * [newCheckinCount] — ascending order, so reaching 50 in one jump also grants 10.
 * SPEC §21 — a no-op when `poiCreatorId` is null (an unclaimed POI has no one to award
 * to yet; once a real check-in photo claims it, future check-ins award normally).
 */
async function awardPoiMilestones(
  tx: Db,
  poiCreatorId: string | null,
  newCheckinCount: number,
): Promise<void> {
  if (!poiCreatorId) return;
  for (const milestone of MILESTONES) {
    if (newCheckinCount >= milestone) {
      await award(tx, poiCreatorId, `poi_milestone_${milestone}` as BadgeKey);
    }
  }
}

export async function awardBadgesForVerifiedCheckin(
  tx: Db,
  input: { userId: string; h3R7: bigint; poiCreatorId: string | null; newPoiCheckinCount: number },
): Promise<void> {
  await awardFirstInRegion(tx, input.userId, input.h3R7);
  await awardPoiMilestones(tx, input.poiCreatorId, input.newPoiCheckinCount);
}

export interface BadgeView {
  badgeKey: BadgeKey;
  awardedAt: string;
}

export async function listBadges(db: Db, userId: string): Promise<BadgeView[]> {
  const rows = await db
    .select({ badgeKey: badges.badgeKey, awardedAt: badges.awardedAt })
    .from(badges)
    .where(eq(badges.userId, userId))
    .orderBy(badges.awardedAt);
  return rows.map((r) => ({
    badgeKey: r.badgeKey as BadgeKey,
    awardedAt: r.awardedAt.toISOString(),
  }));
}
