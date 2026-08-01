import { cellToLatLng, cellToParent, latLngToCell } from 'h3-js';
import { SPEC_CONSTANTS } from '../constants.js';
import type { LatLng } from './distance.js';

/** H3 cell (res 7) used for coverage and leaderboards. SPEC §2 GEO. */
export function coverageCell(p: LatLng): string {
  return latLngToCell(p.lat, p.lng, SPEC_CONSTANTS.geo.H3_RES_COVERAGE);
}

/** H3 cell (res 9) used for POI dedupe candidate bucketing. SPEC §2 GEO. */
export function dedupeCell(p: LatLng): string {
  return latLngToCell(p.lat, p.lng, SPEC_CONSTANTS.geo.H3_RES_DEDUPE);
}

/** H3 cells are stored as BIGINT columns; h3-js uses hex strings. */
export function h3ToBigint(cell: string): bigint {
  return BigInt(`0x${cell}`);
}

export function bigintToH3(value: bigint): string {
  return value.toString(16);
}

/**
 * SPEC §15 — maps a map-camera zoom to one of `COVERAGE_HEATMAP_RESOLUTIONS`, coarsest
 * to finest; `null` at/above the pin-mode threshold (13, matching `GET /pois`'s existing
 * cluster/pin split — one boundary shared across both maps, not a second magic number).
 */
export function resolutionForZoom(zoom: number): number | null {
  if (zoom < 4) return 2;
  if (zoom < 6) return 3;
  if (zoom < 9) return 5;
  if (zoom < 13) return SPEC_CONSTANTS.geo.H3_RES_COVERAGE;
  return null;
}

/** H3 ancestor of [cell] at [resolution] — a no-op when already at that resolution. */
export function coverageAncestor(cell: string, resolution: number): string {
  return resolution === SPEC_CONSTANTS.geo.H3_RES_COVERAGE ? cell : cellToParent(cell, resolution);
}

export function coverageCentroid(cell: string): LatLng {
  const [lat, lng] = cellToLatLng(cell);
  return { lat, lng };
}
