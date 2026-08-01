import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/map/map_controller.dart';
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

void main() {
  test('load at zoom >= 13 populates pois and clears clusters', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois', 200, {
      'pois': [
        {
          'id': 'p1',
          'title': 'A Place',
          'category': 'landmark',
          'location': {'lat': 1.0, 'lng': 2.0},
          'checkinCount': 3,
        },
      ],
      'clusters': [],
    });
    final api = WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(adapter),
      ),
    );
    final controller = MapController(api);

    await controller.load(_bbox, 15);

    expect(controller.state.loading, isFalse);
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.result.pois, hasLength(1));
    expect(controller.state.result.pois.single.title, 'A Place');
    expect(controller.state.result.clusters, isEmpty);

    final sentQuery = adapter.requests.single.queryParameters;
    expect(sentQuery['bbox'], '-10.0,-10.0,10.0,10.0');
    expect(sentQuery['zoom'], 15);
  });

  test('load below the cluster threshold populates clusters and clears pois', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois', 200, {
      'pois': [],
      'clusters': [
        {
          'h3': 'abc123',
          'count': 42,
          'centroid': {'lat': 1.0, 'lng': 2.0},
        },
      ],
    });
    final api = WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(adapter),
      ),
    );
    final controller = MapController(api);

    await controller.load(_bbox, 8);

    expect(controller.state.result.clusters, hasLength(1));
    expect(controller.state.result.clusters.single.count, 42);
    expect(controller.state.result.pois, isEmpty);
  });

  test('a server error surfaces as errorMessage without throwing', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois', 400, {
      'error': {'code': 'request/invalid', 'message': 'bbox wider/taller than 2°'},
    });
    final api = WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(adapter),
      ),
    );
    final controller = MapController(api);

    await controller.load(_bbox, 15);

    expect(controller.state.loading, isFalse);
    expect(controller.state.errorMessage, 'bbox wider/taller than 2°');
  });
}
