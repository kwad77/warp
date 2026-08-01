import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/api_exception.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';

import '../helpers/fake_adapter.dart';

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

ResponseBody _json(int statusCode, Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(bytes, statusCode, headers: {
    Headers.contentTypeHeader: ['application/json'],
  });
}

void main() {
  late FakeAdapter adapter;
  late TokenStore tokenStore;
  late int sessionExpiredCalls;
  late ApiClient client;

  setUp(() {
    adapter = FakeAdapter();
    tokenStore = TokenStore(storage: _InMemorySecureStore());
    sessionExpiredCalls = 0;
    client = ApiClient(
      baseUrl: 'http://test',
      tokenStore: tokenStore,
      onSessionExpired: () => sessionExpiredCalls++,
      dio: buildFakeDio(adapter),
    );
  });

  test('attaches the bearer token when one is stored', () async {
    await tokenStore.save(accessToken: 'tok-123', refreshToken: 'ref-123');
    adapter.onJson('GET', '/v1/pois/abc', 200, {
      'poi': {'id': 'abc'},
    });

    await client.getJson('/v1/pois/abc');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer tok-123');
  });

  test('sends no Authorization header when nothing is stored (🌐 endpoints)', () async {
    adapter.onJson('GET', '/v1/pois/abc', 200, {
      'poi': {'id': 'abc'},
    });
    await client.getJson('/v1/pois/abc');
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('a plain success response is returned as-is', () async {
    adapter.onJson('GET', '/v1/me', 200, {
      'user': {'handle': 'explorer_x'},
    });
    final body = await client.getJson('/v1/me');
    expect(body, {
      'user': {'handle': 'explorer_x'},
    });
  });

  test('a non-auth error throws ApiException with the parsed SPEC §3 envelope', () async {
    adapter.onJson('POST', '/v1/pois', 422, {
      'error': {
        'code': 'poi/outside_pin_adjust',
        'message': 'too far',
        'details': {'distanceM': 99},
      },
    });
    await expectLater(
      client.postJson('/v1/pois', body: {}),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'poi/outside_pin_adjust')),
    );
  });

  test('401 triggers exactly one refresh, then retries the original request once', () async {
    await tokenStore.save(accessToken: 'stale-token', refreshToken: 'good-refresh');

    var meAttempts = 0;
    adapter.on('GET', '/v1/me', (options) {
      meAttempts++;
      final token = options.headers['Authorization'];
      if (token == 'Bearer fresh-token') {
        return _json(200, {
          'user': {'handle': 'explorer_x'},
        });
      }
      return _json(401, {
        'error': {'code': 'auth/expired', 'message': 'Token has expired'},
      });
    });
    adapter.onJson('POST', '/v1/auth/refresh', 200, {
      'accessToken': 'fresh-token',
      'refreshToken': 'fresh-refresh',
    });

    final body = await client.getJson('/v1/me');

    expect(body, {
      'user': {'handle': 'explorer_x'},
    });
    expect(meAttempts, 2); // stale attempt + retry with the fresh token
    expect(await tokenStore.readAccessToken(), 'fresh-token');
    expect(sessionExpiredCalls, 0);
  });

  test(
    'refresh failure clears tokens, calls onSessionExpired once, and propagates the 401',
    () async {
      await tokenStore.save(accessToken: 'stale-token', refreshToken: 'dead-refresh');
      adapter.onJson('GET', '/v1/me', 401, {
        'error': {'code': 'auth/expired', 'message': 'Token has expired'},
      });
      adapter.onJson('POST', '/v1/auth/refresh', 403, {
        'error': {'code': 'auth/refresh_reused', 'message': 'Refresh token reuse detected'},
      });

      await expectLater(client.getJson('/v1/me'), throwsA(isA<ApiException>()));

      expect(sessionExpiredCalls, 1);
      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    },
  );

  test('a 401 on /v1/auth/refresh itself is never retried (no recursive refresh)', () async {
    await tokenStore.save(accessToken: 'stale-token', refreshToken: 'stale-refresh');
    var refreshAttempts = 0;
    adapter.on('POST', '/v1/auth/refresh', (options) {
      refreshAttempts++;
      return _json(401, {
        'error': {'code': 'auth/invalid', 'message': 'nope'},
      });
    });

    await expectLater(
      client.postJson('/v1/auth/refresh', body: {'refreshToken': 'stale-refresh'}),
      throwsA(isA<ApiException>()),
    );
    expect(refreshAttempts, 1);
    expect(sessionExpiredCalls, 0); // the interceptor only reacts to non-auth endpoints
  });

  test('no stored refresh token: refresh is skipped, tokens cleared, session-expired fires', () async {
    // An access token with no refresh token — e.g. corrupted/partial storage.
    final partialStore = _InMemorySecureStore();
    await partialStore.write('wanderpost.access_token', 'stale-token');
    final bareTokenStore = TokenStore(storage: partialStore);
    var bareSessionExpiredCalls = 0;
    final bareClient = ApiClient(
      baseUrl: 'http://test',
      tokenStore: bareTokenStore,
      onSessionExpired: () => bareSessionExpiredCalls++,
      dio: buildFakeDio(adapter),
    );
    adapter.onJson('GET', '/v1/me', 401, {
      'error': {'code': 'auth/expired', 'message': 'Token has expired'},
    });
    var refreshAttempts = 0;
    adapter.on('POST', '/v1/auth/refresh', (options) {
      refreshAttempts++;
      return _json(200, {'accessToken': 'x', 'refreshToken': 'y'});
    });

    await expectLater(bareClient.getJson('/v1/me'), throwsA(isA<ApiException>()));

    expect(refreshAttempts, 0);
    expect(bareSessionExpiredCalls, 1);
    expect(await bareTokenStore.readAccessToken(), isNull);
  });
}
