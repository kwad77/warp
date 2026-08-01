import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/poi/photo_uploader.dart';
import 'package:wanderpost/features/poi/poi_create_outbox.dart';
import 'package:wanderpost/features/poi/poi_create_outbox_controller.dart';
import 'package:wanderpost/models/gps_fix.dart';
import 'package:wanderpost/models/lat_lng.dart';

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

class _FakePhotoUploader implements PhotoUploader {
  final List<String> uploadedUrls = [];

  @override
  Future<void> upload(String url, dynamic bytes, {required String contentType}) async {
    uploadedUrls.add(url);
  }
}

final _gpsFix = GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1));
const _location = LatLng(lat: 38.7, lng: -9.1);

Map<String, dynamic> _poiJson(String id) => {
      'id': id,
      'title': 'Torre',
      'category': 'landmark',
      'location': {'lat': 38.7, 'lng': -9.1},
      'checkinCount': 0,
      'description': null,
      'creator': {'id': 'u1', 'handle': 'explorer_x'},
      'checkinRadiusM': 75,
      'gallery': <Map<String, dynamic>>[],
    };

void main() {
  late Directory tempDir;
  late FakeAdapter adapter;
  late WanderpostApi api;
  late PoiCreateOutbox outbox;
  late _FakePhotoUploader uploader;
  late PoiCreateOutboxController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('poi_create_outbox_controller_test_');
    adapter = FakeAdapter();
    api = WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(adapter),
      ),
    );
    outbox = PoiCreateOutbox(directoryProvider: () async => tempDir);
    uploader = _FakePhotoUploader();
    controller = PoiCreateOutboxController(api: api, outbox: outbox, uploader: uploader);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('replay with an empty outbox does nothing', () async {
    await controller.load();
    await controller.replay();
    expect(controller.state.items, isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('a queued item with no photo replays and is removed on success', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    adapter.onJson('POST', '/v1/pois', 201, {'poi': _poiJson('poi1')});
    await controller.load();

    await controller.replay();

    expect(controller.state.items, isEmpty);
    expect(controller.state.replaying, isFalse);
    final req = adapter.requests.single;
    final body = req.data as Map<String, dynamic>;
    expect(body['title'], 'Torre');
    expect(body['force'], isNull);
  });

  test('a photo is uploaded against the newly-created id after replay succeeds', () async {
    final item = await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
      photoBytes: Uint8List.fromList([1, 2, 3]),
    );
    adapter.onJson('POST', '/v1/pois', 201, {'poi': _poiJson('poi1')});
    adapter.onJson('POST', '/v1/pois/poi1/photos/presign', 201, {
      'uploadUrl': 'https://storage.example/upload',
      'storageKey': 'photos/poi1/ph1.jpg',
      'maxBytes': 1048576,
    });
    adapter.onJson('POST', '/v1/pois/poi1/photos/complete', 201, {
      'photo': {
        'id': 'ph1',
        'urlCard': '/media/card/ph1',
        'urlThumb': '/media/thumb/ph1',
        'voteScore': 0,
        'uploader': {'handle': 'explorer_x'},
        'status': 'pending',
      },
    });
    await controller.load();

    await controller.replay();

    expect(uploader.uploadedUrls, ['https://storage.example/upload']);
    expect(controller.state.items, isEmpty);
    expect(File(item.photoPath!).existsSync(), isFalse);
  });

  test('a dedupeCandidates response auto-resubmits with force: true', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    var calls = 0;
    adapter.on('POST', '/v1/pois', (options) {
      calls++;
      if (calls == 1) {
        return _jsonBody(200, {
          'dedupeCandidates': [
            {
              'id': 'p1',
              'title': 'Existing',
              'category': 'landmark',
              'location': {'lat': 38.7, 'lng': -9.1},
              'checkinCount': 3,
            },
          ],
        });
      }
      return _jsonBody(201, {'poi': _poiJson('poi1')});
    });
    await controller.load();

    await controller.replay();

    expect(calls, 2);
    final forcedBody = adapter.requests.last.data as Map<String, dynamic>;
    expect(forcedBody['force'], true);
    expect(controller.state.items, isEmpty);
  });

  test('a photo upload failure is swallowed — the POI creation still counts as done', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
      photoBytes: Uint8List.fromList([1, 2, 3]),
    );
    adapter.onJson('POST', '/v1/pois', 201, {'poi': _poiJson('poi1')});
    adapter.onJson('POST', '/v1/pois/poi1/photos/presign', 400, {
      'error': {'code': 'request/invalid', 'message': 'bad content type'},
    });
    await controller.load();

    await controller.replay();

    expect(controller.state.items, isEmpty);
  });

  test('a non-network error (e.g. poi/outside_pin_adjust) drops the item, no retry', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    adapter.onJson('POST', '/v1/pois', 422, {
      'error': {'code': 'poi/outside_pin_adjust', 'message': 'Pin too far from GPS fix'},
    });
    await controller.load();

    await controller.replay();

    expect(controller.state.items, isEmpty);
    expect(await outbox.load(), isEmpty);
  });

  test('a network failure stops the whole pass, leaving every item queued', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    await outbox.add(
      title: 'Miradouro',
      category: 'viewpoint',
      location: _location,
      gpsFix: _gpsFix,
    );
    adapter.on(
      'POST',
      '/v1/pois',
      (options) =>
          throw DioException(requestOptions: options, type: DioExceptionType.connectionError),
    );
    await controller.load();

    await controller.replay();

    expect(controller.state.items, hasLength(2));
    expect(controller.state.replaying, isFalse);
  });

  test('a rate/limited response stops the whole pass too — transient, not a verdict', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    adapter.onJson('POST', '/v1/pois', 429, {
      'error': {'code': 'rate/limited', 'message': 'Too many POIs created today'},
    });
    await controller.load();

    await controller.replay();

    expect(controller.state.items, hasLength(1));
    expect(await outbox.load(), hasLength(1));
  });
}

ResponseBody _jsonBody(int statusCode, Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}
