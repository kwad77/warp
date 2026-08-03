import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/features/map/map_query.dart';
import 'package:wanderpost/models/coverage_heatmap_cell.dart';
import 'package:wanderpost/models/lat_lng.dart';

void main() {
  group('zoomForQuery', () {
    test('rounds to the nearest integer', () {
      expect(zoomForQuery(12.4), 12);
      expect(zoomForQuery(12.6), 13);
    });

    test('clamps to [0, 22]', () {
      expect(zoomForQuery(-3.0), 0);
      expect(zoomForQuery(30.0), 22);
    });
  });

  group('BoundingBox.contains', () {
    const bbox = BoundingBox(west: -10, south: -10, east: 10, north: 10);

    test('true for a point inside the box', () {
      expect(bbox.contains(const LatLng(lat: 0, lng: 0)), isTrue);
    });

    test('false for a point outside the box', () {
      expect(bbox.contains(const LatLng(lat: 20, lng: 0)), isFalse);
      expect(bbox.contains(const LatLng(lat: 0, lng: 20)), isFalse);
    });

    test('handles an antimeridian-crossing box (west > east)', () {
      const crossing = BoundingBox(west: 170, south: -10, east: -170, north: 10);
      expect(crossing.contains(const LatLng(lat: 0, lng: 175)), isTrue);
      expect(crossing.contains(const LatLng(lat: 0, lng: -175)), isTrue);
      expect(crossing.contains(const LatLng(lat: 0, lng: 0)), isFalse);
    });
  });

  group('clusterRadius', () {
    test('grows with count but stays within [10, 30]', () {
      final small = clusterRadius(2);
      final medium = clusterRadius(50);
      final huge = clusterRadius(100000);

      expect(small, greaterThanOrEqualTo(10));
      expect(medium, greaterThan(small));
      expect(huge, lessThanOrEqualTo(30));
    });
  });

  group('nearestHeatmapCell', () {
    test('returns null for an empty cell list', () {
      expect(nearestHeatmapCell(const [], const LatLng(lat: 0, lng: 0)), isNull);
    });

    test('returns the cell whose centroid is closest to the tap', () {
      const near = CoverageHeatmapCell(h3: 'near', count: 1, centroid: LatLng(lat: 1, lng: 1));
      const far = CoverageHeatmapCell(h3: 'far', count: 1, centroid: LatLng(lat: 50, lng: 50));

      final result = nearestHeatmapCell([far, near], const LatLng(lat: 0.9, lng: 0.9));

      expect(result, same(near));
    });
  });
}
