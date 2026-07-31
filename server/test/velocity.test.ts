// SPEC §5.4 — teleport and max-speed rules.
import { describe, expect, it } from 'vitest';
import { type VelocitySample, evaluateVelocity } from '../src/verification/velocity.js';

const T0 = 1_700_000_000_000;
const LISBON: VelocitySample = { lat: 38.7139, lng: -9.13, atMs: T0 };

function later(hours: number, lat: number, lng: number): VelocitySample {
  return { lat, lng, atMs: T0 + hours * 3_600_000 };
}

describe('evaluateVelocity', () => {
  it('no previous check-in → never a violation', () => {
    expect(evaluateVelocity(null, LISBON).violation).toBe(false);
  });

  it('walking across town is fine', () => {
    const r = evaluateVelocity(LISBON, later(1, 38.72, -9.14));
    expect(r.violation).toBe(false);
    expect(r.impliedKmh).toBeLessThan(5);
  });

  it('Lisbon → Porto (~274 km) in 3 h is fine (train)', () => {
    expect(evaluateVelocity(LISBON, later(3, 41.1579, -8.6291)).violation).toBe(false);
  });

  it('Lisbon → Tokyo (~11,150 km) in 2 h exceeds MAX_SPEED_KMH', () => {
    const r = evaluateVelocity(LISBON, later(2, 35.6762, 139.6503));
    expect(r.violation).toBe(true);
    expect(r.reasons).toContain('max_speed');
  });

  it('Lisbon → Tokyo in 14 h is fine (airliner)', () => {
    expect(evaluateVelocity(LISBON, later(14, 35.6762, 139.6503)).violation).toBe(false);
  });

  it('2 km jump in 60 s is a teleport even though implied speed is only 120 km/h', () => {
    const r = evaluateVelocity(LISBON, { lat: 38.7319, lng: -9.13, atMs: T0 + 60_000 });
    expect(r.violation).toBe(true);
    expect(r.reasons).toContain('teleport');
  });

  it('1 km jump in 60 s is under the teleport distance → fine', () => {
    const r = evaluateVelocity(LISBON, { lat: 38.7229, lng: -9.13, atMs: T0 + 60_000 });
    expect(r.violation).toBe(false);
  });

  it('non-monotonic client time is a violation', () => {
    const r = evaluateVelocity(LISBON, { ...LISBON, atMs: T0 - 1000 });
    expect(r.violation).toBe(true);
    expect(r.reasons).toContain('non_monotonic_time');
  });
});
