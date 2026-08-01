// SPEC §5.3/§5.5/§17 — evidence freshness (live vs. deferred check-ins).
import { describe, expect, it } from 'vitest';
import { evaluateFreshness } from '../src/verification/freshness.js';

const NOW = 1_700_000_000_000;

describe('evaluateFreshness', () => {
  it('a fix captured seconds ago passes live mode', () => {
    expect(evaluateFreshness(NOW - 5_000, NOW, 'live').ok).toBe(true);
  });

  it('a fix captured 150 s ago (CHECKIN_LIVE_MAX_AGE_S) passes live mode', () => {
    expect(evaluateFreshness(NOW - 150_000, NOW, 'live').ok).toBe(true);
  });

  it('a fix captured 151 s ago fails live mode', () => {
    expect(evaluateFreshness(NOW - 151_000, NOW, 'live').ok).toBe(false);
  });

  it('a fix captured 23 h ago fails live mode', () => {
    expect(evaluateFreshness(NOW - 23 * 3_600_000, NOW, 'live').ok).toBe(false);
  });

  it('a fix captured 23 h ago passes deferred mode', () => {
    expect(evaluateFreshness(NOW - 23 * 3_600_000, NOW, 'deferred').ok).toBe(true);
  });

  it('a fix captured exactly 24 h (CHECKIN_DEFERRED_MAX_AGE_S) ago passes deferred mode', () => {
    expect(evaluateFreshness(NOW - 86_400_000, NOW, 'deferred').ok).toBe(true);
  });

  it('a fix captured 24 h and 1 s ago fails deferred mode', () => {
    expect(evaluateFreshness(NOW - 86_401_000, NOW, 'deferred').ok).toBe(false);
  });

  it('a fix within the clock-skew allowance in the future passes either mode', () => {
    expect(evaluateFreshness(NOW + 30_000, NOW, 'live').ok).toBe(true);
    expect(evaluateFreshness(NOW + 30_000, NOW, 'deferred').ok).toBe(true);
  });

  it('a fix more than the clock-skew allowance in the future fails either mode', () => {
    expect(evaluateFreshness(NOW + 31_000, NOW, 'live').ok).toBe(false);
    expect(evaluateFreshness(NOW + 31_000, NOW, 'deferred').ok).toBe(false);
  });

  it('reports the age in seconds (positive = past)', () => {
    expect(evaluateFreshness(NOW - 10_000, NOW, 'live').ageS).toBeCloseTo(10, 5);
  });
});
