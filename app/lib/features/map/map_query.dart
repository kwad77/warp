/// Pure helpers extracted out of the map widget so they're unit-testable without a
/// live MapLibre engine (none is available in this sandbox — SPEC §12/§10).
library;

import 'dart:math' as math;

import '../../models/coverage_heatmap_cell.dart';
import '../../models/lat_lng.dart';

class BoundingBox {
  final double west;
  final double south;
  final double east;
  final double north;

  const BoundingBox({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  /// SPEC §15 — client-side viewport filter for `GET /me/map`'s unfiltered `checkedIn`
  /// list (that endpoint takes no bbox). Handles an antimeridian-crossing box (west >
  /// east) even though the server itself doesn't support one for `GET /pois` (§7) — cheap
  /// to get right here, and it isn't this filter's job to reject anything.
  bool contains(LatLng point) {
    final lngInRange =
        west <= east ? point.lng >= west && point.lng <= east : point.lng >= west || point.lng <= east;
    return point.lat >= south && point.lat <= north && lngInRange;
  }
}

/// Server integer zoom from a MapLibre camera's fractional zoom (SPEC §7 `zoom=`).
int zoomForQuery(double cameraZoom) => cameraZoom.round().clamp(0, 22);

/// SPEC §12 — a cluster's circle radius scales with its `count` (log, not linear, so a
/// cluster of thousands doesn't dwarf the map) but is still visibly larger than a lone
/// POI's fixed-radius pin at every count `MapScreen` can receive one for.
double clusterRadius(int count) => (10 + math.log(count + 1) * 4).clamp(10, 30);

/// SPEC §15 — a heatmap layer has no per-feature tap callback the way `CircleManager`
/// pins do, so a map tap in heatmap mode is resolved to "the cell whose centroid is
/// closest" (nearest-center, not hit-testing a hexagon boundary — a good enough proxy at
/// the coarse zooms the heatmap is shown at). Returns `null` for an empty cell list.
CoverageHeatmapCell? nearestHeatmapCell(List<CoverageHeatmapCell> cells, LatLng tap) {
  CoverageHeatmapCell? nearest;
  var nearestDistanceSquared = double.infinity;
  for (final cell in cells) {
    final dLat = cell.centroid.lat - tap.lat;
    final dLng = cell.centroid.lng - tap.lng;
    final distanceSquared = dLat * dLat + dLng * dLng;
    if (distanceSquared < nearestDistanceSquared) {
      nearestDistanceSquared = distanceSquared;
      nearest = cell;
    }
  }
  return nearest;
}
