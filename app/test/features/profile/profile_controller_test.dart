import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/profile/profile_controller.dart';
import 'package:wanderpost/features/profile/profile_state.dart';

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

({WanderpostApi api, FakeAdapter adapter}) _build() {
  final adapter = FakeAdapter();
  final api = WanderpostApi(
    ApiClient(
      baseUrl: 'http://test',
      tokenStore: TokenStore(storage: _InMemorySecureStore()),
      dio: buildFakeDio(adapter),
    ),
  );
  return (api: api, adapter: adapter);
}

void _stubHappyPath(FakeAdapter adapter) {
  adapter.onJson('GET', '/v1/me', 200, {
    'user': {'id': 'u1', 'handle': 'explorer_x', 'createdAt': '2026-01-01T00:00:00Z'},
    'stats': {'checkins': 5, 'cellsCovered': 3, 'poisCreated': 1},
  });
  adapter.onJson('GET', '/v1/me/map', 200, {
    'checkedIn': <Map<String, dynamic>>[],
    'created': <Map<String, dynamic>>[],
    'vaulted': <Map<String, dynamic>>[],
  });
  adapter.onJson('GET', '/v1/me/coverage', 200, {'cells': <String>[], 'count': 3});
  adapter.onJson('GET', '/v1/leaderboards/coverage', 200, {
    'entries': [
      {'rank': 1, 'handle': 'explorer_y', 'cells': 20},
    ],
    'me': {'rank': 7, 'cells': 3},
  });
}

void main() {
  test('starts loading', () {
    final built = _build();
    final controller = ProfileController(built.api);
    expect(controller.state, const ProfileState.loading());
  });

  test('load() combines /me, /me/map, /me/coverage, and the leaderboard into loaded', () async {
    final built = _build();
    _stubHappyPath(built.adapter);
    final controller = ProfileController(built.api);

    await controller.load();

    controller.state.when(
      loading: () => fail('expected loaded'),
      loaded: (user, stats, poiMap, coverageCount, leaderboard) {
        expect(user.handle, 'explorer_x');
        expect(stats.checkins, 5);
        expect(poiMap.created, isEmpty);
        expect(coverageCount, 3);
        expect(leaderboard.entries.single.handle, 'explorer_y');
        expect(leaderboard.me?.rank, 7);
      },
      error: (_) => fail('expected loaded'),
    );
    final leaderboardQuery = built.adapter.requests
        .firstWhere((r) => r.path == '/v1/leaderboards/coverage')
        .queryParameters;
    expect(leaderboardQuery, {'window': 'weekly', 'scope': 'global'});
  });

  test('a failed request transitions to error(message)', () async {
    final built = _build();
    // Stub every endpoint first (so the other three concurrent calls resolve cleanly
    // rather than leaving unawaited rejected futures once /me's failure is caught), then
    // override /me alone to fail.
    _stubHappyPath(built.adapter);
    built.adapter.onJson('GET', '/v1/me', 401, {
      'error': {'code': 'auth/expired', 'message': 'Access token expired'},
    });
    final controller = ProfileController(built.api);

    await controller.load();

    expect(controller.state, const ProfileState.error('Access token expired'));
  });
}
