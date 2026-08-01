import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/features/map/map_query.dart';

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
}
