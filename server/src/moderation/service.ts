// SPEC §6 — apply a moderation verdict to a photo row. Separated from the provider so the
// DB-application logic is testable independent of which provider produced the verdict.
import { SPEC_CONSTANTS } from '../constants.js';
import type { Pg } from '../db/client.js';
import type { Storage } from '../storage/r2.js';
import { computePhotoMetrics } from './phash.js';
import type { ModerationProvider, ModerationVerdict } from './provider.js';

const PHOTOS = SPEC_CONSTANTS.photos;

/**
 * SPEC §21 — the moment a photo clears moderation, if its POI is still unclaimed
 * (`creator_id IS NULL` — a seeded POI nobody has founded yet), that photo's uploader
 * founds it. One statement, guarded by the `IS NULL` check, so it's race-safe and
 * one-shot: whichever approval reaches Postgres first wins; a second photo (or a
 * concurrent approval) for the same POI matches zero rows and is a no-op. Applies
 * uniformly regardless of `photos.source` — a normal user-created POI already has a
 * creator at insert time, so this only ever fires for POIs that started unclaimed.
 */
async function promoteFounderIfUnclaimed(pg: Pg, photoId: string): Promise<void> {
  await pg`
    UPDATE pois p SET creator_id = ph.uploader_id
    FROM photos ph
    WHERE ph.id = ${photoId} AND p.id = ph.poi_id AND p.creator_id IS NULL`;
}

export async function applyModerationVerdict(
  pg: Pg,
  photoId: string,
  verdict: ModerationVerdict,
): Promise<void> {
  if (verdict.outcome === 'rejected') {
    await pg`
      UPDATE photos SET moderation = 'rejected', rejection_reason = ${verdict.reason}
      WHERE id = ${photoId}`;
    return;
  }
  await pg`UPDATE photos SET moderation = ${verdict.outcome} WHERE id = ${photoId}`;
  if (verdict.outcome === 'approved') {
    await promoteFounderIfUnclaimed(pg, photoId);
  }
}

/**
 * SPEC §6 — fetches the real bytes (a GET, unlike the HEAD-only presign/complete
 * validation) to compute pixel dimensions + the 64-bit pHash, storing both on the photo
 * row regardless of outcome. An image whose long edge falls below
 * `UPLOAD_MIN_LONG_EDGE_PX` is rejected here (`reason: 'quality'`) — this is the
 * "pixel-dimension checks" §6 describes, previously deferred alongside the real detector
 * only because it also needed the bytes; sharp being pre-allowlisted means no new
 * dependency decision was actually required for this part. Storage errors (including
 * "not configured") degrade to skipping metrics rather than failing the whole photo —
 * this is best-effort enrichment, not a validation the presign/complete path already
 * didn't perform.
 */
async function computeAndStorePhotoMetrics(
  storage: Storage,
  pg: Pg,
  photoId: string,
  storageKey: string,
): Promise<{ rejected: true } | { rejected: false }> {
  let bytes: Uint8Array | null;
  try {
    bytes = await storage.get(storageKey);
  } catch {
    return { rejected: false };
  }
  if (!bytes) return { rejected: false };

  const metrics = await computePhotoMetrics(bytes);
  await pg`
    UPDATE photos SET width = ${metrics.width}, height = ${metrics.height},
                       phash = ${metrics.phash.toString()}
    WHERE id = ${photoId}`;

  const longEdge = Math.max(metrics.width, metrics.height);
  if (longEdge < PHOTOS.UPLOAD_MIN_LONG_EDGE_PX) {
    await applyModerationVerdict(pg, photoId, { outcome: 'rejected', reason: 'quality' });
    return { rejected: true };
  }
  return { rejected: false };
}

/** M1: invoked synchronously in-process right after insert. See SPEC §6 M1 note. */
export async function runModerationForPhoto(
  provider: ModerationProvider,
  storage: Storage,
  pg: Pg,
  photoId: string,
  storageKey: string,
): Promise<ModerationVerdict> {
  const metrics = await computeAndStorePhotoMetrics(storage, pg, photoId, storageKey);
  if (metrics.rejected) {
    return { outcome: 'rejected', reason: 'quality' };
  }
  const verdict = await provider.moderate({ photoId, storageKey });
  await applyModerationVerdict(pg, photoId, verdict);
  return verdict;
}
