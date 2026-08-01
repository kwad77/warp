import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/constants.dart';
import 'package:wanderpost/core/device_store.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/checkin/checkin_outbox.dart';
import 'package:wanderpost/features/checkin/checkin_outbox_controller.dart';
import 'package:wanderpost/features/checkin/integrity_token_provider.dart';
import 'package:wanderpost/features/poi/photo_uploader.dart';
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

class _FakeIntegrityTokenProvider implements IntegrityTokenProvider {
  @override
  Future<String> token(String nonce) async => 'dev.pass.$nonce';
}

class _FakePhotoUploader implements PhotoUploader {
  final List<String> uploadedUrls = [];

  @override
  Future<void> upload(String url, dynamic bytes, {required String contentType}) async {
    uploadedUrls.add(url);
  }
}

GpsFix _fix(int seconds, {DateTime? base}) => GpsFix(
      lat: 38.7,
      lng: -9.1,
      accuracyM: 10,
      capturedAt: (base ?? DateTime.utc(2026, 1, 1)).add(Duration(seconds: seconds)),
    );

void main() {
  late Directory tempDir;
  late FakeAdapter adapter;
  late WanderpostApi api;
  late CheckinOutbox outbox;
  late DeviceStore deviceStore;
  late _FakePhotoUploader uploader;
  late CheckinOutboxController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checkin_outbox_controller_test_');
    adapter = FakeAdapter();
    api = WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(adapter),
      ),
    );
    outbox = CheckinOutbox(directoryProvider: () async => tempDir);
    final secureStore = _InMemorySecureStore()..write('wanderpost.device_id', 'dev1');
    deviceStore = DeviceStore(storage: secureStore);
    uploader = _FakePhotoUploader();
    controller = CheckinOutboxController(
      api: api,
      outbox: outbox,
      integrityTokenProvider: _FakeIntegrityTokenProvider(),
      uploader: uploader,
      deviceStore: deviceStore,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  void stubIntent(String nonce) {
    adapter.onJson('POST', '/v1/checkins/intent', 201, {'nonce': nonce, 'expiresInS': 120});
  }

  void stubCheckin({int statusCode = 201, Map<String, dynamic>? body}) {
    adapter.onJson(
      'POST',
      '/v1/checkins',
      statusCode,
      body ??
          {
            'checkin': {
              'id': 'c1',
              'poiId': 'poi1',
              'status': 'verified',
              'mode': 'confirm',
              'evidence': 'deferred',
              'createdAt': '2026-01-01T00:00:09.000Z',
              'verifiedAt': '2026-01-01T00:00:09.000Z',
            },
          },
    );
  }

  test('replay with an empty outbox does nothing', () async {
    await controller.load();
    await controller.replay();
    expect(controller.state.items, isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('a confirm-mode item replays with evidence: deferred and is removed on success', () async {
    await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    stubIntent('nonce1');
    stubCheckin();
    await controller.load();

    await controller.replay();

    expect(controller.state.items, isEmpty);
    expect(controller.state.replaying, isFalse);
    final submitReq = adapter.requests.firstWhere((r) => r.path == '/v1/checkins');
    final body = submitReq.data as Map<String, dynamic>;
    expect(body['evidence'], 'deferred');
    expect((body['fixes'] as List).length, 2);
  });

  test('photo mode: replay presigns/uploads/completes then submits with a fresh-nonce token', () async {
    final photoCapturedAt = DateTime.utc(2026, 1, 1, 0, 0, 9);
    await outbox.add(
      poiId: 'poi1',
      mode: 'photo',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.now().subtract(const Duration(hours: 2)),
      photoBytes: Uint8List.fromList([1, 2, 3]),
      photoCapturedAt: photoCapturedAt,
    );
    stubIntent('nonceABC');
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
    stubCheckin(
      body: {
        'checkin': {
          'id': 'c1',
          'poiId': 'poi1',
          'status': 'verified',
          'mode': 'photo',
          'evidence': 'deferred',
          'createdAt': '2026-01-01T00:00:09.000Z',
          'verifiedAt': '2026-01-01T00:00:09.000Z',
        },
      },
    );
    await controller.load();

    await controller.replay();

    expect(uploader.uploadedUrls, ['https://storage.example/upload']);
    final submitReq = adapter.requests.firstWhere((r) => r.path == '/v1/checkins');
    final body = submitReq.data as Map<String, dynamic>;
    final capture = body['capture'] as Map<String, dynamic>;
    expect(capture['storageKey'], 'photos/poi1/ph1.jpg');
    expect(capture['capturedAt'], photoCapturedAt.toIso8601String());
    expect(
      capture['token'],
      crypto.sha256
          .convert(utf8.encode('nonceABC.${photoCapturedAt.millisecondsSinceEpoch}'))
          .toString(),
    );
    expect(controller.state.items, isEmpty);
  });

  test('a non-network error (e.g. checkin/duplicate) drops the item, no retry', () async {
    await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    stubIntent('nonce1');
    adapter.onJson('POST', '/v1/checkins', 409, {
      'error': {'code': 'checkin/duplicate', 'message': 'Already checked in at this POI'},
    });
    await controller.load();

    await controller.replay();

    expect(controller.state.items, isEmpty);
    expect(await outbox.load(), isEmpty);
  });

  test('a network failure stops the whole pass, leaving every item queued', () async {
    await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    await outbox.add(
      poiId: 'poi2',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    adapter.on(
      'POST',
      '/v1/checkins/intent',
      (options) =>
          throw DioException(requestOptions: options, type: DioExceptionType.connectionError),
    );
    await controller.load();

    await controller.replay();

    expect(controller.state.items, hasLength(2));
    expect(controller.state.replaying, isFalse);
  });

  test('an item older than CHECKIN_DEFERRED_MAX_AGE_S is dropped without any network call', () async {
    await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.now().subtract(
        Duration(seconds: AppConfig.checkinDeferredMaxAgeS + 60),
      ),
    );
    await controller.load();

    await controller.replay();

    expect(controller.state.items, isEmpty);
    expect(adapter.requests, isEmpty);
  });
}
