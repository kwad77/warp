import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/feed/feed_controller.dart';
import 'package:wanderpost/features/poi/location_source.dart';
import 'package:wanderpost/models/gps_fix.dart';

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

class _FakeLocationSource implements LocationSource {
  final GpsFix? fix;

  _FakeLocationSource(this.fix);

  @override
  Future<GpsFix> currentFix() async {
    final f = fix;
    if (f == null) throw StateError('Location permission denied');
    return f;
  }

  @override
  Stream<GpsFix> fixStream() => throw UnimplementedError();
}

final _fix = GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1));

Map<String, dynamic> _pinJson(String id, {String? thumbnailUrl}) => {
      'id': id,
      'title': 'Place $id',
      'category': 'landmark',
      'location': {'lat': 38.7, 'lng': -9.1},
      'checkinCount': 1,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };

FeedController _controller(FakeAdapter adapter, {GpsFix? fix}) {
  final api = WanderpostApi(
    ApiClient(
      baseUrl: 'http://test',
      tokenStore: TokenStore(storage: _InMemorySecureStore()),
      dio: buildFakeDio(adapter),
    ),
  );
  return FeedController(api: api, locationSource: _FakeLocationSource(fix ?? _fix));
}

void main() {
  test('load populates nearby and saved from their respective endpoints', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois/nearby', 200, {
      'pois': [_pinJson('p1')],
    });
    adapter.onJson('GET', '/v1/me/map', 200, {
      'checkedIn': <Map<String, dynamic>>[],
      'created': <Map<String, dynamic>>[],
      'saved': [_pinJson('p2', thumbnailUrl: '/media/thumb/p2.jpg')],
      'vaulted': <Map<String, dynamic>>[],
    });
    final controller = _controller(adapter);

    await controller.load();

    expect(controller.state.loading, isFalse);
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.nearby.single.id, 'p1');
    expect(controller.state.saved.single.id, 'p2');
    expect(controller.state.saved.single.thumbnailUrl, '/media/thumb/p2.jpg');
  });

  test('a logged-out visitor still sees nearby when GET /me/map 401s', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois/nearby', 200, {
      'pois': [_pinJson('p1')],
    });
    adapter.onJson('GET', '/v1/me/map', 401, {
      'error': {'code': 'auth/missing', 'message': 'Missing bearer token'},
    });
    final controller = _controller(adapter);

    await controller.load();

    expect(controller.state.nearby.single.id, 'p1');
    expect(controller.state.saved, isEmpty);
    expect(controller.state.errorMessage, isNull);
  });

  test('a location failure surfaces errorMessage but still tries saved', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/me/map', 200, {
      'checkedIn': <Map<String, dynamic>>[],
      'created': <Map<String, dynamic>>[],
      'saved': [_pinJson('p2')],
      'vaulted': <Map<String, dynamic>>[],
    });
    final controller = _controller(adapter, fix: null);

    await controller.load();

    expect(controller.state.nearby, isEmpty);
    expect(controller.state.saved.single.id, 'p2');
    expect(controller.state.errorMessage, isNotNull);
  });

  test('toggleSaved(save) moves a nearby item into saved and calls the API', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois/nearby', 200, {
      'pois': [_pinJson('p1')],
    });
    adapter.onJson('GET', '/v1/me/map', 200, {
      'checkedIn': <Map<String, dynamic>>[],
      'created': <Map<String, dynamic>>[],
      'saved': <Map<String, dynamic>>[],
      'vaulted': <Map<String, dynamic>>[],
    });
    adapter.onJson('POST', '/v1/pois/p1/save', 200, {'saved': true});
    final controller = _controller(adapter);
    await controller.load();

    await controller.toggleSaved('p1');

    expect(controller.state.saved.map((p) => p.id), ['p1']);
    final saveReq = adapter.requests.firstWhere((r) => r.path == '/v1/pois/p1/save');
    expect(saveReq.data, {'value': 1});
  });

  test('toggleSaved(unsave) removes it from saved and calls the API with value: 0', () async {
    final adapter = FakeAdapter();
    adapter.onJson('GET', '/v1/pois/nearby', 200, {'pois': <Map<String, dynamic>>[]});
    adapter.onJson('GET', '/v1/me/map', 200, {
      'checkedIn': <Map<String, dynamic>>[],
      'created': <Map<String, dynamic>>[],
      'saved': [_pinJson('p2')],
      'vaulted': <Map<String, dynamic>>[],
    });
    adapter.onJson('POST', '/v1/pois/p2/save', 200, {'saved': false});
    final controller = _controller(adapter);
    await controller.load();

    await controller.toggleSaved('p2');

    expect(controller.state.saved, isEmpty);
    final saveReq = adapter.requests.firstWhere((r) => r.path == '/v1/pois/p2/save');
    expect(saveReq.data, {'value': 0});
  });
}
