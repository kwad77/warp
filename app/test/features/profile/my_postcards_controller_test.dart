import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/profile/my_postcards_controller.dart';

import '../../helpers/fake_adapter.dart';

ResponseBody _json(int statusCode, Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(bytes, statusCode, headers: {
    Headers.contentTypeHeader: ['application/json'],
  });
}

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

Map<String, dynamic> _postcardJson(String id, {String? revokedAt}) => {
      'id': id,
      'token': 'tok-$id',
      'url': 'http://test/v1/postcards/tok-$id',
      'poiTitle': 'Place $id',
      'createdAt': '2026-01-01T00:00:00Z',
      'revokedAt': revokedAt,
    };

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

void main() {
  test('load() populates postcards, newest first, including a revoked one', () async {
    final built = _build();
    built.adapter.on('GET', '/v1/me/postcards', (options) {
      return _json(200, {
        'postcards': [_postcardJson('a'), _postcardJson('b', revokedAt: '2026-01-02T00:00:00Z')],
      });
    });
    final controller = MyPostcardsController(built.api);

    await controller.load();

    expect(controller.state.postcards.map((p) => p.id), ['a', 'b']);
    expect(controller.state.postcards[1].revokedAt, isNotNull);
    expect(controller.state.loading, isFalse);
  });

  test('a failed load() surfaces errorMessage', () async {
    final built = _build();
    built.adapter.onJson('GET', '/v1/me/postcards', 401, {
      'error': {'code': 'auth/expired', 'message': 'Access token expired'},
    });
    final controller = MyPostcardsController(built.api);

    await controller.load();

    expect(controller.state.errorMessage, 'Access token expired');
  });

  test('revoke() marks the matching row revoked, in place, without touching the others', () async {
    final built = _build();
    built.adapter.on('GET', '/v1/me/postcards', (options) {
      return _json(200, {
        'postcards': [_postcardJson('a'), _postcardJson('b')],
      });
    });
    built.adapter.onJson('DELETE', '/v1/postcards/a', 200, {'ok': true});
    final controller = MyPostcardsController(built.api);
    await controller.load();

    await controller.revoke('a');

    expect(controller.state.postcards[0].id, 'a');
    expect(controller.state.postcards[0].revokedAt, isNotNull);
    expect(controller.state.postcards[1].id, 'b');
    expect(controller.state.postcards[1].revokedAt, isNull);
  });

  test('a failed revoke() surfaces errorMessage without touching the list', () async {
    final built = _build();
    built.adapter.on('GET', '/v1/me/postcards', (options) {
      return _json(200, {
        'postcards': [_postcardJson('a')],
      });
    });
    built.adapter.onJson('DELETE', '/v1/postcards/a', 404, {
      'error': {'code': 'resource/not_found', 'message': 'No such postcard'},
    });
    final controller = MyPostcardsController(built.api);
    await controller.load();

    await controller.revoke('a');

    expect(controller.state.errorMessage, 'No such postcard');
    expect(controller.state.postcards[0].revokedAt, isNull);
  });
}
