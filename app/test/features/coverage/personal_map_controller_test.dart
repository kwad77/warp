import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/coverage/personal_map_controller.dart';
import 'package:wanderpost/features/coverage/personal_map_state.dart';
import 'package:wanderpost/features/map/map_query.dart';

import '../../helpers/fake_adapter.dart';

class _InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

const _bbox = BoundingBox(west: -10, south: -10, east: 10, north: 10);

WanderpostApi _apiWith(FakeAdapter adapter) => WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(adapter),
      ),
    );

void main() {
  test('load below the pin-mode threshold fetches the coverage heatmap', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/me/coverage/heatmap', 200, {
      'cells': [
        {
          'h3': 'abc123',
          'count': 3,
          'centroid': {'lat': 1.0, 'lng': 2.0},
        },
      ],
      'resolution': 5,
    });
    final controller = PersonalMapController(_apiWith(adapter));

    await controller.load(_bbox, 8);

    expect(controller.state.loading, isFalse);
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.mode, PersonalMapMode.heatmap);
    expect(controller.state.heatmapCells, hasLength(1));
    expect(controller.state.heatmapCells.single.count, 3);
    expect(adapter.requests.single.queryParameters['zoom'], 8);
  });

  test('load at/above the pin-mode threshold fetches postcards and nearby POIs', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/me/map', 200, {
      'checkedIn': [
        {
          'id': 'p1',
          'title': 'Inside',
          'category': 'landmark',
          'location': {'lat': 1.0, 'lng': 1.0},
          'checkinCount': 1,
        },
        {
          'id': 'p2',
          'title': 'Outside',
          'category': 'landmark',
          'location': {'lat': 50.0, 'lng': 50.0},
          'checkinCount': 1,
        },
      ],
      'created': <Map<String, dynamic>>[],
      'vaulted': <Map<String, dynamic>>[],
    });
    adapter.onJson('GET', '/v1/pois', 200, {
      'pois': [
        {
          'id': 'p3',
          'title': 'Nearby',
          'category': 'landmark',
          'location': {'lat': 2.0, 'lng': 2.0},
          'checkinCount': 5,
        },
      ],
      'clusters': [],
    });
    final controller = PersonalMapController(_apiWith(adapter));

    await controller.load(_bbox, 15);

    expect(controller.state.mode, PersonalMapMode.pins);
    expect(controller.state.myPostcards, hasLength(1));
    expect(controller.state.myPostcards.single.id, 'p1');
    expect(controller.state.nearbyPois, hasLength(1));
    expect(controller.state.nearbyPois.single.id, 'p3');
  });

  test('a cached GET /me/map is reused (not re-fetched) across pin-mode loads', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/me/map', 200, {
      'checkedIn': <Map<String, dynamic>>[],
      'created': <Map<String, dynamic>>[],
      'vaulted': <Map<String, dynamic>>[],
    });
    adapter.onJson('GET', '/v1/pois', 200, {'pois': <Map<String, dynamic>>[], 'clusters': <Map<String, dynamic>>[]});
    final controller = PersonalMapController(_apiWith(adapter));

    await controller.load(_bbox, 15);
    await controller.load(_bbox, 15);

    final meMapCalls = adapter.requests.where((r) => r.path == '/v1/me/map');
    expect(meMapCalls, hasLength(1));
    final poisCalls = adapter.requests.where((r) => r.path == '/v1/pois');
    expect(poisCalls, hasLength(2));
  });

  test('a server error surfaces as errorMessage without throwing', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/me/coverage/heatmap', 400, {
      'error': {'code': 'request/invalid', 'message': 'zoom out of range'},
    });
    final controller = PersonalMapController(_apiWith(adapter));

    await controller.load(_bbox, 8);

    expect(controller.state.loading, isFalse);
    expect(controller.state.errorMessage, 'zoom out of range');
  });
}
