// SPEC §5.3 — L2 Presence. Pure: no I/O, no clock reads; time arrives in the fixes.
import { SPEC_CONSTANTS } from '../constants.js';
import { type LatLng, haversineM } from '../geo/distance.js';

const P = SPEC_CONSTANTS.presence;

export interface GpsFix extends LatLng {
  accuracyM: number;
  /** Unix epoch milliseconds as reported by the client. */
  capturedAtMs: number;
}

export type PresenceOutcome = 'pass' | 'pass_degraded' | 'pending' | 'reject';

export interface PresenceResult {
  outcome: PresenceOutcome;
  reasons: string[];
  /** Best usable fix, if any fix was under the accuracy ceiling. */
  best?: { index: number; confidence: number; distanceM: number };
}

/**
 * Containment confidence: c = clamp01((r + a − d) / (2a)). A fix whose accuracy circle
 * comfortably overlaps the check-in radius passes even when the fix itself is imprecise.
 */
export function containmentConfidence(
  distanceM: number,
  accuracyM: number,
  radiusM: number,
): number {
  const a = accuracyM <= 0 ? 5 : accuracyM;
  const c = (radiusM + a - distanceM) / (2 * a);
  return Math.min(1, Math.max(0, c));
}

export function evaluatePresence(
  fixes: readonly GpsFix[],
  poi: LatLng,
  radiusM: number,
): PresenceResult {
  const reasons: string[] = [];
  if (fixes.length === 0) return { outcome: 'reject', reasons: ['no_fixes'] };

  const times = fixes.map((f) => f.capturedAtMs);
  const spanS = (Math.max(...times) - Math.min(...times)) / 1000;
  const spanOk = spanS >= P.FIX_SPAN_MIN_S && spanS <= P.FIX_WINDOW_MAX_S;
  if (!spanOk) reasons.push('fix_span');

  const usable = fixes
    .map((f, index) => ({ f, index }))
    .filter(({ f }) => f.accuracyM <= P.ACCURACY_CEILING_M);
  if (usable.length === 0) return { outcome: 'reject', reasons: [...reasons, 'accuracy_ceiling'] };
  if (usable.length < fixes.length) reasons.push('accuracy_ceiling_partial');

  const maxAccuracy = Math.max(...usable.map(({ f }) => f.accuracyM));
  const consistencyLimit = Math.max(P.TRACK_CONSISTENCY_FLOOR_M, 2 * maxAccuracy);
  let trackConsistent = true;
  for (let i = 0; i < usable.length && trackConsistent; i++) {
    for (let j = i + 1; j < usable.length; j++) {
      const a = usable[i];
      const b = usable[j];
      if (a && b && haversineM(a.f, b.f) > consistencyLimit) {
        trackConsistent = false;
        break;
      }
    }
  }
  if (!trackConsistent) reasons.push('inconsistent_track');

  let best: { index: number; confidence: number; distanceM: number } | undefined;
  for (const { f, index } of usable) {
    const distanceM = haversineM(f, poi);
    const confidence = containmentConfidence(distanceM, f.accuracyM, radiusM);
    if (!best || confidence > best.confidence) best = { index, confidence, distanceM };
  }
  // usable is non-empty, so best is set.
  const c = (best as NonNullable<typeof best>).confidence;

  let outcome: PresenceOutcome;
  if (c >= P.CONF_PASS) outcome = 'pass';
  else if (c >= P.CONF_DEGRADED) outcome = 'pass_degraded';
  else if (c >= P.CONF_PENDING) {
    outcome = 'pending';
    reasons.push('low_confidence');
  } else {
    outcome = 'reject';
    reasons.push('outside_radius');
  }

  // Caps: track inconsistency or a bad fix span degrade a pass to pending, never upgrade.
  if ((!trackConsistent || !spanOk) && (outcome === 'pass' || outcome === 'pass_degraded')) {
    outcome = 'pending';
  }
  return { outcome, reasons, best: best as NonNullable<typeof best> };
}
