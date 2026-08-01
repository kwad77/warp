// SPEC §6 — moderation provider seam. DevModerationProvider is M1's only real
// implementation; RekognitionModerationProvider is a named stub, not wired to any SDK
// (adding one is a dependency decision outside the §1 allowlist — see SPEC §6 M1 note).
import { notImplemented } from '../errors.js';

export type ModerationVerdict =
  | { outcome: 'approved' }
  | { outcome: 'rejected'; reason: 'people' | 'unsafe' | 'quality' | 'other' }
  | { outcome: 'escalated' };

export interface ModerationProvider {
  moderate(input: { photoId: string; storageKey: string }): Promise<ModerationVerdict>;
}

/** M1: synchronous, instant, always approves. Logs so the pipeline is visible in dev. */
export function devModerationProvider(log: (msg: string) => void): ModerationProvider {
  return {
    async moderate({ photoId, storageKey }) {
      log(`[dev-moderation] auto-approving ${photoId} (${storageKey})`);
      return { outcome: 'approved' };
    },
  };
}

/** Seam only — no detector wired in. Selecting this provider is a 501, not a crash. */
export function rekognitionModerationProvider(): ModerationProvider {
  return {
    async moderate() {
      throw notImplemented('Rekognition moderation provider');
    },
  };
}

export function createModerationProvider(
  kind: 'dev' | 'rekognition',
  log: (msg: string) => void,
): ModerationProvider {
  return kind === 'rekognition' ? rekognitionModerationProvider() : devModerationProvider(log);
}
