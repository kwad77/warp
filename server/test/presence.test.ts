// SPEC §5.3 — includes every worked example from the spec, verbatim.
import { describe, expect, it } from 'vitest';
import {
  type GpsFix,
  containmentConfidence,
  evaluatePresence,
} from '../src/verification/presence.js';

const POI = { lat: 38.7139, lng: -9.13 };
const R = 75;

/** Offset a point ~north by meters (1e-5 deg lat ≈ 1.11 m). */
function north(meters: number): { lat: number; lng: number } {
  return { lat: POI.lat + meters / 111_320, lng: POI.lng };
}

function fix(distanceM: number, accuracyM: number, atS: number): GpsFix {
  return { ...north(distanceM), accuracyM, capturedAtMs: 1_700_000_000_000 + atS * 1000 };
}

/** Two consistent fixes spanning 10 s at the same spot/accuracy. */
function pair(distanceM: number, accuracyM: number): GpsFix[] {
  return [fix(distanceM, accuracyM, 0), fix(distanceM, accuracyM, 10)];
}

describe('containmentConfidence (SPEC §5.3 worked examples)', () => {
  it('d=20 a=60 r=75 → ≈0.958 (pass band)', () => {
    expect(containmentConfidence(20, 60, R)).toBeCloseTo(0.958, 2);
  });
  it('d=75 a=60 r=75 → 0.5 (pending band)', () => {
    expect(containmentConfidence(75, 60, R)).toBeCloseTo(0.5, 5);
  });
  it('d=130 a=60 r=75 → ≈0.04 (reject band)', () => {
    expect(containmentConfidence(130, 60, R)).toBeCloseTo(0.0417, 3);
  });
  it('d=0 a=150 r=75 → 0.75 (degraded band)', () => {
    expect(containmentConfidence(0, 150, R)).toBeCloseTo(0.75, 5);
  });
  it('clamps to [0, 1]', () => {
    expect(containmentConfidence(0, 5, R)).toBe(1);
    expect(containmentConfidence(10_000, 5, R)).toBe(0);
  });
  it('treats accuracy 0 as 5 m instead of dividing by zero', () => {
    expect(containmentConfidence(0, 0, R)).toBe(1);
    expect(Number.isFinite(containmentConfidence(200, 0, R))).toBe(true);
  });
});

describe('evaluatePresence', () => {
  it('passes a precise on-site pair', () => {
    const r = evaluatePresence(pair(20, 60), POI, R);
    expect(r.outcome).toBe('pass');
    expect(r.best?.confidence).toBeGreaterThanOrEqual(0.9);
  });

  it('degrades an imprecise-but-centered fix (d=0, a=150)', () => {
    expect(evaluatePresence(pair(0, 150), POI, R).outcome).toBe('pass_degraded');
  });

  it('pends the borderline case (d=75, a=60)', () => {
    const r = evaluatePresence(pair(75, 60), POI, R);
    expect(r.outcome).toBe('pending');
    expect(r.reasons).toContain('low_confidence');
  });

  it('rejects far-away fixes (d=130, a=60)', () => {
    const r = evaluatePresence(pair(130, 60), POI, R);
    expect(r.outcome).toBe('reject');
    expect(r.reasons).toContain('outside_radius');
  });

  it('rejects when every fix is above the accuracy ceiling', () => {
    const r = evaluatePresence(pair(10, 200), POI, R);
    expect(r.outcome).toBe('reject');
    expect(r.reasons).toContain('accuracy_ceiling');
  });

  it('caps at pending when the track is inconsistent (fixes 500 m apart)', () => {
    const r = evaluatePresence([fix(0, 30, 0), fix(500, 30, 10)], POI, R);
    expect(r.outcome).toBe('pending');
    expect(r.reasons).toContain('inconsistent_track');
  });

  it('caps at pending when the fix span is too short', () => {
    const r = evaluatePresence([fix(10, 20, 0), fix(10, 20, 2)], POI, R);
    expect(r.outcome).toBe('pending');
    expect(r.reasons).toContain('fix_span');
  });

  it('still hard-rejects out-of-radius even with a bad span (cap never upgrades)', () => {
    const r = evaluatePresence([fix(2000, 20, 0), fix(2000, 20, 2)], POI, R);
    expect(r.outcome).toBe('reject');
  });

  it('rejects an empty fix list', () => {
    expect(evaluatePresence([], POI, R).outcome).toBe('reject');
  });
});
