// SPEC §6 — apply a moderation verdict to a photo row. Separated from the provider so the
// DB-application logic is testable independent of which provider produced the verdict.
import type { Pg } from '../db/client.js';
import type { ModerationProvider, ModerationVerdict } from './provider.js';

export async function applyModerationVerdict(
  pg: Pg,
  photoId: string,
  verdict: ModerationVerdict,
): Promise<void> {
  if (verdict.outcome === 'rejected') {
    await pg`
      UPDATE photos SET moderation = 'rejected', rejection_reason = ${verdict.reason}
      WHERE id = ${photoId}`;
  } else {
    await pg`UPDATE photos SET moderation = ${verdict.outcome} WHERE id = ${photoId}`;
  }
}

/** M1: invoked synchronously in-process right after insert. See SPEC §6 M1 note. */
export async function runModerationForPhoto(
  provider: ModerationProvider,
  pg: Pg,
  photoId: string,
  storageKey: string,
): Promise<ModerationVerdict> {
  const verdict = await provider.moderate({ photoId, storageKey });
  await applyModerationVerdict(pg, photoId, verdict);
  return verdict;
}
