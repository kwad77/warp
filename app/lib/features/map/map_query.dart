/// Pure helpers extracted out of the map widget so they're unit-testable without a
/// live MapLibre engine (none is available in this sandbox — SPEC §12/§10).
library;

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
}

/// Server integer zoom from a MapLibre camera's fractional zoom (SPEC §7 `zoom=`).
int zoomForQuery(double cameraZoom) => cameraZoom.round().clamp(0, 22);
