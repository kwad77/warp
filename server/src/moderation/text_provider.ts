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

// SPEC §21 — a starter list for display-name moderation, not an attempt at an exhaustive
// or definitive profanity dictionary. Deliberately mild/representative rather than
// enumerating slurs; meant to be extended (or replaced by a real vendor) before a public
// launch, same spirit as this codebase's other flagged judgment calls (categoryFor's OSM
// mapping, dHashFromGrayscale's algorithm choice).
export const DEFAULT_DISPLAY_NAME_BLOCKLIST: readonly string[] = [
  'fuck',
  'shit',
  'bitch',
  'asshole',
  'bastard',
  'cunt',
  'dick',
  'piss',
  'slut',
  'whore',
];

const LEETSPEAK: Record<string, string> = {
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '4': 'a',
  '5': 's',
  '7': 't',
  $: 's',
  '@': 'a',
};

// Unicode combining diacritical marks (U+0300–U+036F), used after NFD normalization
// to strip accents (e.g. "e" + U+0301 -> "e"). The lint rule below assumes a combining-
// mark range is always an accident; here it is deliberately the whole point.
// biome-ignore lint/suspicious/noMisleadingCharacterClass: intentional accent-stripping range, not an accidental match against a composed character.
const COMBINING_MARKS_RE = /[\u0300-\u036f]/g;

/**
 * Lowercase, strip diacritics, fold common leetspeak substitutions, then drop every
 * remaining non-alphanumeric character — so "F.u_c-k" and "fu4k" both collapse to
 * something a substring check on the blocklist can catch. This intentionally trades
 * precision for recall: a short substring match on a stripped string can false-positive
 * on innocuous words that contain a blocked one (the "Scunthorpe problem" — e.g. a
 * blocklisted "ass" would flag "assassin"). The blocklist above sticks to whole
 * profanity words for exactly this reason; it's still a known, accepted limitation of a
 * first-pass keyword filter, not a solved general profanity detector.
 */
function normalize(text: string): string {
  const folded = text
    .normalize('NFD')
    .replace(COMBINING_MARKS_RE, '')
    .toLowerCase()
    .split('')
    .map((ch) => LEETSPEAK[ch] ?? ch)
    .join('');
  return folded.replace(/[^a-z0-9]/g, '');
}

/** SPEC §21 — a real (if simple) detector, not another always-approves stub. */
export function keywordTextModerationProvider(
  blocklist: readonly string[] = DEFAULT_DISPLAY_NAME_BLOCKLIST,
): TextModerationProvider {
  const normalizedBlocklist = blocklist.map(normalize);
  return {
    async moderate(text: string) {
      const normalized = normalize(text);
      const flagged = normalizedBlocklist.some(
        (word) => word.length > 0 && normalized.includes(word),
      );
      return { approved: !flagged };
    },
  };
}
