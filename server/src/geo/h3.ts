import { latLngToCell } from 'h3-js';
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
