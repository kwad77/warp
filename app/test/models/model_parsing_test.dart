import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/models/cluster.dart';
import 'package:wanderpost/models/poi.dart';
import 'package:wanderpost/models/poi_pin.dart';
import 'package:wanderpost/models/pois_result.dart';

void main() {
  test('PoiPin.fromMap parses the SPEC §7 shape', () {
    final pin = PoiPin.fromMap({
      'id': 'p1',
      'title': 'Miradouro',
      'category': 'viewpoint',
      'location': {'lat': 38.7, 'lng': -9.1},
      'checkinCount': 5,
    });
    expect(pin.id, 'p1');
    expect(pin.location.lat, 38.7);
    expect(pin.checkinCount, 5);
  });

  test('Cluster.fromMap parses centroid', () {
    final cluster = Cluster.fromMap({
      'h3': 'abcdef',
      'count': 12,
      'centroid': {'lat': 1.5, 'lng': 2.5},
    });
    expect(cluster.count, 12);
    expect(cluster.centroid.lng, 2.5);
  });

  test('PoisResult.fromMap parses pois and clusters independently', () {
    final result = PoisResult.fromMap({
      'pois': [
        {
          'id': 'p1',
          'title': 'x',
          'category': 'landmark',
          'location': {'lat': 1, 'lng': 2},
          'checkinCount': 1,
        },
      ],
      'clusters': <Map<String, dynamic>>[],
    });
    expect(result.pois, hasLength(1));
    expect(result.clusters, isEmpty);
  });

  test('Poi.fromMap parses the full shape including gallery and creator', () {
    final poi = Poi.fromMap({
      'id': 'poi1',
      'title': 'Torre',
      'category': 'landmark',
      'location': {'lat': 1, 'lng': 2},
      'checkinCount': 10,
      'description': 'A tower.',
      'creator': {'id': 'u1', 'handle': 'explorer_x'},
      'checkinRadiusM': 75,
      'gallery': [
        {
          'id': 'ph1',
          'urlCard': '/media/card/x',
          'urlThumb': '/media/thumb/x',
          'voteScore': 3,
          'uploader': {'handle': 'explorer_y'},
          'status': 'approved',
        },
      ],
    });
    expect(poi.creatorHandle, 'explorer_x');
    expect(poi.gallery.single.uploaderHandle, 'explorer_y');
    expect(poi.description, 'A tower.');
  });

  test('Poi.fromMap handles a null description', () {
    final poi = Poi.fromMap({
      'id': 'poi1',
      'title': 'Torre',
      'category': 'landmark',
      'location': {'lat': 1, 'lng': 2},
      'checkinCount': 0,
      'description': null,
      'creator': {'id': 'u1', 'handle': 'explorer_x'},
      'checkinRadiusM': 75,
      'gallery': <Map<String, dynamic>>[],
    });
    expect(poi.description, isNull);
    expect(poi.gallery, isEmpty);
  });
}
