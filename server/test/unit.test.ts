import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';
import { AppError, ERROR_STATUS } from '../src/errors.js';
import { haversineM } from '../src/geo/distance.js';
import {
  bigintToH3,
  coverageAncestor,
  coverageCell,
  coverageCentroid,
  dedupeCell,
  h3ToBigint,
  resolutionForZoom,
} from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';

const BASE_ENV = { JWT_SECRET: 'test-secret-that-is-at-least-32-chars!!' };

describe('config', () => {
  it('applies defaults', () => {
    const c = loadConfig(BASE_ENV);
    expect(c.NODE_ENV).toBe('development');
    expect(c.PORT).toBe(8080);
  });
  it('rejects a short JWT_SECRET', () => {
    expect(() => loadConfig({ JWT_SECRET: 'short' })).toThrow(/JWT_SECRET/);
  });
  it('rejects a malformed DATABASE_URL', () => {
    expect(() => loadConfig({ ...BASE_ENV, DATABASE_URL: 'nope' })).toThrow(
      /Invalid configuration/,
    );
  });
});

describe('uuidv7', () => {
  it('is RFC-9562 shaped with version 7', () => {
    const id = uuidv7();
    expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });
  it('sorts by generation time', () => {
    const a = uuidv7(1_700_000_000_000);
    const b = uuidv7(1_700_000_100_000);
    expect(a < b).toBe(true);
  });
});

describe('h3 helpers (SPEC §2 GEO)', () => {
  const lisbon = { lat: 38.7139, lng: -9.13 };
  it('coverage cell is res 7 and stable', () => {
    expect(coverageCell(lisbon)).toBe(coverageCell({ lat: 38.7141, lng: -9.1302 }));
  });
  it('dedupe cell (res 9) is finer than coverage (res 7)', () => {
    expect(dedupeCell(lisbon)).not.toBe(coverageCell(lisbon));
  });
  it('bigint round-trip preserves the cell', () => {
    const cell = coverageCell(lisbon);
    expect(bigintToH3(h3ToBigint(cell))).toBe(cell);
  });
});

describe('resolutionForZoom (SPEC §15)', () => {
  it('maps each zoom band to the documented resolution', () => {
    expect(resolutionForZoom(0)).toBe(2);
    expect(resolutionForZoom(3)).toBe(2);
    expect(resolutionForZoom(4)).toBe(3);
    expect(resolutionForZoom(5)).toBe(3);
    expect(resolutionForZoom(6)).toBe(5);
    expect(resolutionForZoom(8)).toBe(5);
    expect(resolutionForZoom(9)).toBe(7);
    expect(resolutionForZoom(12)).toBe(7);
  });
  it('returns null at/above the pin-mode threshold (13, matching GET /pois)', () => {
    expect(resolutionForZoom(13)).toBeNull();
    expect(resolutionForZoom(22)).toBeNull();
  });
});

describe('coverageAncestor / coverageCentroid (SPEC §15)', () => {
  const lisbon = { lat: 38.7139, lng: -9.13 };
  it('at resolution 7 (H3_RES_COVERAGE) is a no-op', () => {
    const cell = coverageCell(lisbon);
    expect(coverageAncestor(cell, 7)).toBe(cell);
  });
  it('a coarser resolution collapses nearby cells to the same ancestor', () => {
    const a = coverageCell(lisbon);
    const b = coverageCell({ lat: lisbon.lat + 0.01, lng: lisbon.lng + 0.01 });
    expect(coverageAncestor(a, 2)).toBe(coverageAncestor(b, 2));
  });
  it('centroid is close to the original point at the fine resolution', () => {
    const cell = coverageCell(lisbon);
    const centroid = coverageCentroid(cell);
    expect(Math.abs(centroid.lat - lisbon.lat)).toBeLessThan(0.02);
    expect(Math.abs(centroid.lng - lisbon.lng)).toBeLessThan(0.02);
  });
});

describe('haversine', () => {
  it('Lisbon → Porto ≈ 274 km', () => {
    const d = haversineM({ lat: 38.7139, lng: -9.13 }, { lat: 41.1579, lng: -8.6291 });
    expect(d).toBeGreaterThan(265_000);
    expect(d).toBeLessThan(285_000);
  });
  it('zero distance for identical points', () => {
    expect(haversineM({ lat: 1, lng: 2 }, { lat: 1, lng: 2 })).toBe(0);
  });
});

describe('error envelope (SPEC §3)', () => {
  it('maps codes to statuses', () => {
    expect(ERROR_STATUS['checkin/nonce_expired']).toBe(410);
    expect(new AppError('rate/limited', 'x', { retryAfterS: 60 }).status).toBe(429);
  });
  it('omits details when absent', () => {
    expect(new AppError('auth/missing', 'x').toBody().error).not.toHaveProperty('details');
  });
});
