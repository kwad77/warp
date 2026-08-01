// SPEC §5.3/§5.5/§17 — evidence freshness. Pure: no I/O, no clock reads; `nowMs` arrives
// as a parameter same as everywhere else in this module.
import { SPEC_CONSTANTS } from '../constants.js';

const E = SPEC_CONSTANTS.evidence;

export type EvidenceMode = 'live' | 'deferred';

export interface FreshnessResult {
  ok: boolean;
  ageS: number;
}

/**
 * `capturedAtMs` must be no more than `CLOCK_SKEW_S` in the future and no older than the
 * mode's max age (`CHECKIN_LIVE_MAX_AGE_S` or `CHECKIN_DEFERRED_MAX_AGE_S`). A violation is
 * evidence integrity, not a confidence signal — callers hard-reject(`stale_evidence`) on
 * `!ok`, they never merely cap.
 */
export function evaluateFreshness(
  capturedAtMs: number,
  nowMs: number,
  mode: EvidenceMode,
): FreshnessResult {
  const maxAgeS = mode === 'deferred' ? E.CHECKIN_DEFERRED_MAX_AGE_S : E.CHECKIN_LIVE_MAX_AGE_S;
  const ageS = (nowMs - capturedAtMs) / 1000;
  const ok = ageS >= -E.CLOCK_SKEW_S && ageS <= maxAgeS;
  return { ok, ageS };
}
