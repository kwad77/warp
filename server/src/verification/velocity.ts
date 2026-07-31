// SPEC §5.4 — L3 Velocity. Pure. Violations cap at pending upstream, never hard-reject.
import { SPEC_CONSTANTS } from '../constants.js';
import { type LatLng, haversineM } from '../geo/distance.js';

const V = SPEC_CONSTANTS.velocity;

export interface VelocitySample extends LatLng {
  atMs: number;
}

export interface VelocityResult {
  violation: boolean;
  reasons: string[];
  impliedKmh?: number;
  distanceM?: number;
}

export function evaluateVelocity(
  prev: VelocitySample | null,
  current: VelocitySample,
): VelocityResult {
  if (prev === null) return { violation: false, reasons: [] };

  const distanceM = haversineM(prev, current);
  const dtS = (current.atMs - prev.atMs) / 1000;
  if (dtS <= 0) {
    // Client clock ran backwards relative to the previous check-in: suspicious by itself.
    return { violation: true, reasons: ['non_monotonic_time'], distanceM };
  }

  const impliedKmh = distanceM / 1000 / (dtS / 3600);
  const reasons: string[] = [];
  if (impliedKmh > V.MAX_SPEED_KMH) reasons.push('max_speed');
  if (dtS < V.TELEPORT_WINDOW_S && distanceM > V.TELEPORT_DISTANCE_M) reasons.push('teleport');
  return { violation: reasons.length > 0, reasons, impliedKmh, distanceM };
}
