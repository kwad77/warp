// SPEC §20 — a minimal text-moderation seam for postcard messages, mirroring
// moderation/provider.ts's photo pattern: one real (dev, always-approves) implementation,
// no detector wired in yet. Deliberately smaller than the photo verdict shape — nothing
// consumes a rejection reason (a rejected message just isn't rendered, §20), so there's
// no reason taxonomy to invent.
export interface TextModerationVerdict {
  approved: boolean;
}

export interface TextModerationProvider {
  moderate(text: string): Promise<TextModerationVerdict>;
}

/** M1/M2: synchronous, instant, always approves. */
export function devTextModerationProvider(): TextModerationProvider {
  return {
    async moderate() {
      return { approved: true };
    },
  };
}
