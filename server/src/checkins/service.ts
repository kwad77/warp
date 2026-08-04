// SPEC §5 — the check-in pipeline orchestrator. Layers L1–L5 in order; pure math lives
// in src/verification/; this module owns I/O, ordering, and evidence persistence.
import { createHash, randomBytes } from 'node:crypto';
import { and, count, desc, eq, gt, inArray, sql } from 'drizzle-orm';
import { awardBadgesForVerifiedCheckin } from '../badges/service.js';
import { SPEC_CONSTANTS } from '../constants.js';
import type { Db, Pg } from '../db/client.js';
import {
  checkinEvidence,
  checkinNonces,
  checkins,
  devices,
  photos,
  pois,
  userCoverage,
  users,
} from '../db/schema.js';
import { AppError } from '../errors.js';
import { coverageCell, h3ToBigint } from '../geo/h3.js';
import { uuidv7 } from '../lib/uuid.js';
import { recordTrustEvent } from '../trust/service.js';
import { type EvidenceMode, evaluateFreshness } from '../verification/freshness.js';
import type { IntegrityVerifier } from '../verification/integrity.js';
import { type GpsFix, type PresenceResult, evaluatePresence } from '../verification/presence.js';
import { type VelocityResult, evaluateVelocity } from '../verification/velocity.js';

const N = SPEC_CONSTANTS.nonce;
const T = SPEC_CONSTANTS.trust;
const RATE = SPEC_CONSTANTS.rate;

function sha256(input: string): string {
  return createHash('sha256').update(input).digest('hex');
}

export interface CheckinView {
  id: string;
  poiId: string;
  status: 'verified' | 'pending' | 'rejected';
  mode: 'photo' | 'confirm';
  evidence: EvidenceMode;
  createdAt: string;
  verifiedAt?: string;
}

interface PoiRow {
  id: string;
  lat: number;
  lng: number;
  radiusM: number;
  status: string;
  // SPEC §21 — null for an unclaimed (seeded) POI nobody has founded yet.
  creatorId: string | null;
}

async function loadPoi(pg: Pg, poiId: string): Promise<PoiRow | null> {
  const rows = await pg`
    SELECT id, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
           checkin_radius_m AS radius, status, creator_id
    FROM pois WHERE id = ${poiId}`;
  const r = rows[0];
  if (!r) return null;
  return {
    id: r.id as string,
    lat: Number(r.lat),
    lng: Number(r.lng),
    radiusM: Number(r.radius),
    status: r.status as string,
    creatorId: r.creator_id as string | null,
  };
}

async function hasLiveCheckin(db: Db, userId: string, poiId: string): Promise<boolean> {
  const rows = await db
    .select({ id: checkins.id })
    .from(checkins)
    .where(
      and(
        eq(checkins.userId, userId),
        eq(checkins.poiId, poiId),
        inArray(checkins.status, ['verified', 'pending']),
      ),
    )
    .limit(1);
  return rows.length > 0;
}

export async function createIntent(
  db: Db,
  pg: Pg,
  userId: string,
  poiId: string,
  deviceId: string,
  now: Date,
): Promise<{ nonce: string; expiresInS: number }> {
  const device = (
    await db
      .select({ id: devices.id, userId: devices.userId })
      .from(devices)
      .where(eq(devices.id, deviceId))
  )[0];
  if (!device || device.userId !== userId) {
    throw new AppError('resource/not_found', 'Unknown device');
  }
  const poi = await loadPoi(pg, poiId);
  if (!poi || poi.status === 'removed') {
    throw new AppError('resource/not_found', 'Unknown POI');
  }
  if (await hasLiveCheckin(db, userId, poiId)) {
    throw new AppError('checkin/duplicate', 'Already checked in at this POI');
  }
  const hourAgo = new Date(now.getTime() - 3_600_000);
  const [recent] = await db
    .select({ n: count() })
    .from(checkinNonces)
    .where(and(eq(checkinNonces.userId, userId), gt(checkinNonces.expiresAt, hourAgo)));
  if ((recent?.n ?? 0) >= RATE.CHECKIN_INTENT_PER_HOUR) {
    throw new AppError('rate/limited', 'Too many check-in attempts', { retryAfterS: 3600 });
  }
  const nonce = randomBytes(32).toString('base64url');
  await db.insert(checkinNonces).values({
    nonceHash: sha256(nonce),
    userId,
    deviceId,
    poiId,
    expiresAt: new Date(now.getTime() + N.CHECKIN_NONCE_TTL_S * 1000),
  });
  return { nonce, expiresInS: N.CHECKIN_NONCE_TTL_S };
}

export interface SubmitInput {
  nonce: string;
  poiId: string;
  mode: 'photo' | 'confirm';
  fixes: { lat: number; lng: number; accuracyM: number; capturedAt: string }[];
  integrityToken: string;
  evidence?: EvidenceMode;
  capture?: { token: string; capturedAt: string; storageKey: string };
}

export async function submitCheckin(
  db: Db,
  pg: Pg,
  verifier: IntegrityVerifier,
  userId: string,
  input: SubmitInput,
  now: Date,
): Promise<CheckinView> {
  // Nonce: single-use, consumed regardless of outcome. SPEC §5.7.
  const consumed = await db
    .update(checkinNonces)
    .set({ used: true })
    .where(
      and(
        eq(checkinNonces.nonceHash, sha256(input.nonce)),
        eq(checkinNonces.used, false),
        gt(checkinNonces.expiresAt, now),
        eq(checkinNonces.userId, userId),
        eq(checkinNonces.poiId, input.poiId),
      ),
    )
    .returning({ expiresAt: checkinNonces.expiresAt, deviceId: checkinNonces.deviceId });
  const nonceRow = consumed[0];
  if (!nonceRow) {
    throw new AppError('checkin/nonce_expired', 'Nonce is missing, used, or expired');
  }
  if (await hasLiveCheckin(db, userId, input.poiId)) {
    throw new AppError('checkin/duplicate', 'Already checked in at this POI');
  }
  const poi = await loadPoi(pg, input.poiId);
  if (!poi || poi.status === 'removed') {
    throw new AppError('resource/not_found', 'Unknown POI');
  }
  const user = (
    await db.select({ trust: users.trustScore }).from(users).where(eq(users.id, userId))
  )[0];
  if (!user) throw new AppError('auth/invalid', 'Unknown user');

  const evidence: EvidenceMode = input.evidence ?? 'live';
  const reasons: string[] = [];
  let status: 'verified' | 'pending' | 'rejected' = 'verified';
  const cap = (r: string) => {
    if (status === 'verified') status = 'pending';
    reasons.push(r);
  };

  // L1 integrity
  const integrity = await verifier.verify(input.integrityToken, input.nonce);
  if (integrity.outcome === 'fail') {
    status = 'rejected';
    reasons.push('integrity');
  } else if (integrity.outcome === 'degraded') {
    cap('integrity_degraded');
  }

  // Evidence freshness (SPEC §5.3/§17) — hard reject, short-circuits like L1.
  const gpsFixes: GpsFix[] = input.fixes.map((f) => ({
    lat: f.lat,
    lng: f.lng,
    accuracyM: f.accuracyM,
    capturedAtMs: Date.parse(f.capturedAt),
  }));
  if (status !== 'rejected') {
    const latestFixMs = Math.max(...gpsFixes.map((f) => f.capturedAtMs));
    if (!evaluateFreshness(latestFixMs, now.getTime(), evidence).ok) {
      status = 'rejected';
      reasons.push('stale_evidence');
    }
  }

  // L2 presence
  let presence: PresenceResult | null = null;
  if (status !== 'rejected') {
    presence = evaluatePresence(gpsFixes, poi, poi.radiusM);
    if (presence.outcome === 'reject') {
      status = 'rejected';
      reasons.push(...presence.reasons);
    } else if (presence.outcome === 'pending') {
      for (const r of presence.reasons) cap(r);
    } else if (presence.outcome === 'pass_degraded') {
      reasons.push('presence_degraded');
    }
  }

  // L3 velocity — previous live check-in's POI location + time.
  let velocity: VelocityResult | null = null;
  if (status !== 'rejected' && presence?.best) {
    const prevRows = await pg`
      SELECT ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
             c.created_at AS at
      FROM checkins c JOIN pois p ON p.id = c.poi_id
      WHERE c.user_id = ${userId} AND c.status IN ('verified','pending')
      ORDER BY c.created_at DESC LIMIT 1`;
    const prev = prevRows[0];
    const bestIdx = presence.best.index;
    const bestFix = gpsFixes[bestIdx];
    if (prev && bestFix) {
      velocity = evaluateVelocity(
        {
          lat: Number(prev.lat),
          lng: Number(prev.lng),
          atMs: new Date(prev.at as string).getTime(),
        },
        { lat: bestFix.lat, lng: bestFix.lng, atMs: bestFix.capturedAtMs },
      );
      if (velocity.violation) {
        cap('velocity');
      }
    }
  }

  // L4 capture (photo mode)
  let photoId: string | null = null;
  let captureEvidence: Record<string, unknown> | null = null;
  if (status !== 'rejected' && input.mode === 'photo') {
    const c = input.capture;
    const capturedAtMs = c ? Date.parse(c.capturedAt) : Number.NaN;
    const tokenOk = c && c.token === sha256(`${input.nonce}.${capturedAtMs}`);
    const timeOk = c ? evaluateFreshness(capturedAtMs, now.getTime(), evidence).ok : false;
    const photo = c
      ? (
          await db
            .select({ id: photos.id })
            .from(photos)
            .where(
              and(
                eq(photos.storageKey, c.storageKey),
                eq(photos.uploaderId, userId),
                eq(photos.poiId, input.poiId),
                eq(photos.source, 'checkin'),
              ),
            )
        )[0]
      : undefined;
    captureEvidence = {
      tokenOk: !!tokenOk,
      timeOk,
      photoFound: !!photo,
      clientCapturedAt: c?.capturedAt ?? null,
      serverReceivedAt: now.toISOString(),
    };
    if (!tokenOk || !timeOk || !photo) {
      status = 'rejected';
      reasons.push('capture_invalid');
    } else {
      photoId = photo.id;
    }
  }

  // L5 trust gate
  if (status !== 'rejected') {
    if (user.trust < T.TRUST_PHOTO_REQUIRED_BELOW && input.mode === 'confirm') {
      status = 'rejected';
      reasons.push('photo_required');
    } else if (
      user.trust < T.TRUST_PHOTO_REQUIRED_BELOW ||
      user.trust < T.TRUST_MANUAL_REVIEW_BELOW
    ) {
      cap('trust_gate');
    }
  }

  const checkinId = uuidv7(now.getTime());
  const verifiedAt = status === 'verified' ? now : null;
  const cell = presence?.best
    ? coverageCell(gpsFixes[presence.best.index] as GpsFix)
    : coverageCell(poi);

  await db.transaction(async (tx) => {
    await tx.insert(checkins).values({
      id: checkinId,
      userId,
      poiId: input.poiId,
      mode: input.mode,
      photoId,
      status,
      h3R7: h3ToBigint(coverageCell(poi)),
      evidence,
      verifiedAt,
    });
    await tx.insert(checkinEvidence).values({
      checkinId,
      fixes: input.fixes,
      bestFix: presence?.best ?? {},
      distanceM: presence?.best ? String(presence.best.distanceM.toFixed(1)) : null,
      integrity: { ...integrity, nonceConsumedAt: now.toISOString(), deviceId: nonceRow.deviceId },
      velocity: velocity as unknown as Record<string, unknown> | null,
      capture: captureEvidence,
      verdicts: { final: status, reasons, coverageCell: cell },
    });
    if (status === 'verified') {
      const cellId = h3ToBigint(coverageCell(poi));
      await tx
        .insert(userCoverage)
        .values({ userId, h3R7: cellId, firstCheckinId: checkinId })
        .onConflictDoNothing();
      const updated = await tx
        .update(pois)
        .set({ checkinCount: sql`${pois.checkinCount} + 1` })
        .where(eq(pois.id, input.poiId))
        .returning({ checkinCount: pois.checkinCount });
      // SPEC §16 (M2) — same transaction as the coverage insert/count increment above, so
      // a rolled-back check-in never awards a badge.
      await awardBadgesForVerifiedCheckin(tx, {
        userId,
        h3R7: cellId,
        poiCreatorId: poi.creatorId,
        newPoiCheckinCount: updated[0]?.checkinCount ?? 0,
      });
    }
  });

  // Trust events outside the check-in transaction: they must survive even when rejected.
  if (reasons.includes('integrity')) {
    await recordTrustEvent(db, userId, 'integrity_fail', { checkinId }, now);
  }
  if (reasons.includes('velocity')) {
    await recordTrustEvent(db, userId, 'velocity_violation', { checkinId }, now);
  }

  const view: CheckinView = {
    id: checkinId,
    poiId: input.poiId,
    status,
    mode: input.mode,
    evidence,
    createdAt: now.toISOString(),
    ...(verifiedAt ? { verifiedAt: verifiedAt.toISOString() } : {}),
  };
  if (status === 'rejected') {
    throw new AppError('checkin/rejected', 'Check-in could not be verified', {
      checkinId,
      reasons,
    });
  }
  return view;
}

export async function getCheckin(db: Db, userId: string, id: string): Promise<CheckinView> {
  const row = (
    await db
      .select()
      .from(checkins)
      .where(and(eq(checkins.id, id), eq(checkins.userId, userId)))
  )[0];
  if (!row) throw new AppError('resource/not_found', 'No such check-in'); // SPEC §5.7: no existence leak
  return {
    id: row.id,
    poiId: row.poiId,
    status: row.status,
    mode: row.mode,
    evidence: row.evidence,
    createdAt: row.createdAt.toISOString(),
    ...(row.verifiedAt ? { verifiedAt: row.verifiedAt.toISOString() } : {}),
  };
}

export const _internals = { sha256, hasLiveCheckin };
