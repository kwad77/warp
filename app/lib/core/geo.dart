import 'dart:math' as math;

import '../models/lat_lng.dart';

const _earthRadiusM = 6371008.8;

/// Great-circle distance in meters (haversine) — mirrors `server/src/geo/distance.ts`
/// exactly, since local checks here (SPEC §13.1's pin-adjust hint) are advisory only;
/// the server (same formula) is the source of truth.
double haversineM(LatLng a, LatLng b) {
  double toRad(double d) => d * math.pi / 180;
  final dLat = toRad(b.lat - a.lat);
  final dLng = toRad(b.lng - a.lng);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat + math.cos(toRad(a.lat)) * math.cos(toRad(b.lat)) * sinLng * sinLng;
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}
