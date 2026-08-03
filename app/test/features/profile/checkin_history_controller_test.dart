import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/profile/checkin_history_controller.dart';

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

Map<String, dynamic> _itemJson(String id, {String status = 'verified'}) => {
      'id': id,
      'poiId': 'poi-$id',
      'poiTitle': 'Place $id',
      'poiCategory': 'landmark',
      'status': status,
      'mode': 'confirm',
      'evidence': 'live',
      'createdAt': '2026-01-01T00:00:00Z',
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
  test('load() populates items and nextCursor from the first page', () async {
    final built = _build();
    built.adapter.on('GET', '/v1/me/checkins', (options) {
      expect(options.queryParameters.containsKey('cursor'), isFalse);
      return _json(200, {
        'items': [_itemJson('a'), _itemJson('b', status: 'pending')],
        'nextCursor': 'page2',
      });
    });
    final controller = CheckinHistoryController(built.api);

    await controller.load();

    expect(controller.state.items.map((i) => i.id), ['a', 'b']);
    expect(controller.state.items[1].status, 'pending');
    expect(controller.state.nextCursor, 'page2');
    expect(controller.state.loading, isFalse);
  });

  test('loadMore() appends the next page and clears nextCursor when exhausted', () async {
    final built = _build();
    built.adapter.on('GET', '/v1/me/checkins', (options) {
      final cursor = options.queryParameters['cursor'];
      if (cursor == null) {
        return _json(200, {
          'items': [_itemJson('a')],
          'nextCursor': 'page2',
        });
      }
      expect(cursor, 'page2');
      return _json(200, {
        'items': [_itemJson('b')],
      });
    });
    final controller = CheckinHistoryController(built.api);

    await controller.load();
    await controller.loadMore();

    expect(controller.state.items.map((i) => i.id), ['a', 'b']);
    expect(controller.state.nextCursor, isNull);
  });

  test('loadMore() is a no-op once nextCursor is null', () async {
    final built = _build();
    var calls = 0;
    built.adapter.on('GET', '/v1/me/checkins', (options) {
      calls++;
      return _json(200, {'items': [_itemJson('a')]});
    });
    final controller = CheckinHistoryController(built.api);

    await controller.load();
    await controller.loadMore();

    expect(calls, 1);
  });

  test('a failed load() surfaces errorMessage', () async {
    final built = _build();
    built.adapter.onJson('GET', '/v1/me/checkins', 401, {
      'error': {'code': 'auth/expired', 'message': 'Access token expired'},
    });
    final controller = CheckinHistoryController(built.api);

    await controller.load();

    expect(controller.state.errorMessage, 'Access token expired');
  });
}
