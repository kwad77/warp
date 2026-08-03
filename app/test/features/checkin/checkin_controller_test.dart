import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/checkin/checkin_controller.dart';
import 'package:wanderpost/features/checkin/checkin_outbox.dart';
import 'package:wanderpost/features/checkin/checkin_state.dart';
import 'package:wanderpost/features/checkin/integrity_token_provider.dart';
import 'package:wanderpost/features/checkin/pending_checkin_photo.dart';
import 'package:wanderpost/features/poi/face_gate.dart';
import 'package:wanderpost/features/poi/location_source.dart';
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

class _FakeLocationSource implements LocationSource {
  final List<GpsFix> fixes;

  _FakeLocationSource(this.fixes);

  @override
  Future<GpsFix> currentFix() => throw UnimplementedError();

  @override
  Stream<GpsFix> fixStream() => Stream.fromIterable(fixes);
}

class _FakeFaceGate implements FaceGate {
  bool result = false;
  final List<String> checkedPaths = [];

  @override
  Future<bool> hasFace(String imagePath) async {
    checkedPaths.add(imagePath);
    return result;
  }
}

class _FakePhotoUploader implements PhotoUploader {
  final List<String> uploadedUrls = [];

  @override
  Future<void> upload(String url, dynamic bytes, {required String contentType}) async {
    uploadedUrls.add(url);
  }
}

class _FakeIntegrityTokenProvider implements IntegrityTokenProvider {
  @override
  Future<String> token(String nonce) async => 'dev.pass.$nonce';
}

GpsFix _fixAt(int seconds) => GpsFix(
      lat: 38.7,
      lng: -9.1,
      accuracyM: 10,
      capturedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
    );

final _twoFixes = [_fixAt(0), _fixAt(9)];

/// Real `CheckinOutbox`, pointed at a fresh temp directory per test — no fake needed,
/// its file-I/O logic just runs for real (see `checkin_outbox_test.dart` for its own
/// dedicated coverage).
CheckinOutbox _tempOutbox() {
  Directory? dir;
  return CheckinOutbox(
    directoryProvider: () async =>
        dir ??= await Directory.systemTemp.createTemp('checkin_outbox_test_'),
  );
}

({
  WanderpostApi api,
  FakeAdapter adapter,
  _FakeLocationSource location,
  _FakeFaceGate faceGate,
  _FakePhotoUploader uploader,
  CheckinOutbox outbox,
}) _build({List<GpsFix>? fixes}) {
  final adapter = FakeAdapter();
  final api = WanderpostApi(
    ApiClient(
      baseUrl: 'http://test',
      tokenStore: TokenStore(storage: _InMemorySecureStore()),
      dio: buildFakeDio(adapter),
    ),
  );
  return (
    api: api,
    adapter: adapter,
    location: _FakeLocationSource(fixes ?? _twoFixes),
    faceGate: _FakeFaceGate(),
    uploader: _FakePhotoUploader(),
    outbox: _tempOutbox(),
  );
}

CheckinController _controller(
  ({
    WanderpostApi api,
    FakeAdapter adapter,
    _FakeLocationSource location,
    _FakeFaceGate faceGate,
    _FakePhotoUploader uploader,
    CheckinOutbox outbox,
  }) built,
) =>
    CheckinController(
      api: built.api,
      locationSource: built.location,
      integrityTokenProvider: _FakeIntegrityTokenProvider(),
      faceGate: built.faceGate,
      uploader: built.uploader,
      outbox: built.outbox,
    );

void _stubIntent(FakeAdapter adapter, {String nonce = 'nonce123'}) {
  adapter.onJson('POST', '/v1/checkins/intent', 201, {'nonce': nonce, 'expiresInS': 120});
}

void _stubCheckin(FakeAdapter adapter, {required String status}) {
  adapter.onJson('POST', '/v1/checkins', 201, {
    'checkin': {
      'id': 'c1',
      'poiId': 'poi1',
      'status': status,
      'mode': 'confirm',
      'evidence': 'live',
      'createdAt': '2026-01-01T00:00:09.000Z',
      if (status == 'verified') 'verifiedAt': '2026-01-01T00:00:09.000Z',
    },
  });
}

void main() {
  test('confirm mode success (verified) never touches photo endpoints', () async {
    final built = _build();
    _stubIntent(built.adapter);
    _stubCheckin(built.adapter, status: 'verified');
    final controller = _controller(built);

    await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

    expect(controller.state, isA<CheckinState>());
    controller.state.when(
      idle: () => fail('expected verified'),
      inProgress: () => fail('expected verified'),
      verified: (checkin) => expect(checkin.id, 'c1'),
      pending: (_) => fail('expected verified'),
      rejected: (_) => fail('expected verified'),
      duplicate: () => fail('expected verified'),
      photoBlocked: () => fail('expected verified'),
      photoProcessingFailed: () => fail('expected verified'),
      fixTimeout: () => fail('expected verified'),
      error: (_) => fail('expected verified'),
      queued: () => fail('expected verified'),
    );
    expect(built.uploader.uploadedUrls, isEmpty);
    final submitBody = built.adapter.requests.last.data as Map<String, dynamic>;
    expect(submitBody['mode'], 'confirm');
    expect(submitBody['capture'], isNull);
    expect((submitBody['fixes'] as List).length, 2);
    expect(submitBody['integrityToken'], 'dev.pass.nonce123');
  });

  test('confirm mode pending status transitions to pending', () async {
    final built = _build();
    _stubIntent(built.adapter);
    _stubCheckin(built.adapter, status: 'pending');
    final controller = _controller(built);

    await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

    expect(controller.state, isA<CheckinState>());
    controller.state.maybeWhen(pending: (c) => expect(c.status, 'pending'), orElse: () => fail('expected pending'));
  });

  test('checkin/duplicate transitions to duplicate', () async {
    final built = _build();
    _stubIntent(built.adapter);
    built.adapter.onJson('POST', '/v1/checkins', 409, {
      'error': {'code': 'checkin/duplicate', 'message': 'Already checked in at this POI'},
    });
    final controller = _controller(built);

    await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

    expect(controller.state, const CheckinState.duplicate());
  });

  test('checkin/rejected surfaces details.reasons', () async {
    final built = _build();
    _stubIntent(built.adapter);
    built.adapter.onJson('POST', '/v1/checkins', 422, {
      'error': {
        'code': 'checkin/rejected',
        'message': 'Check-in could not be verified',
        'details': {
          'checkinId': 'c1',
          'reasons': ['outside_radius'],
        },
      },
    });
    final controller = _controller(built);

    await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

    expect(controller.state, const CheckinState.rejected(['outside_radius']));
  });

  test('checkin/nonce_expired retries once with a fresh intent, then succeeds', () async {
    final built = _build();
    var intentCalls = 0;
    built.adapter.on('POST', '/v1/checkins/intent', (options) {
      intentCalls++;
      return _jsonBody(201, {'nonce': 'nonce-$intentCalls', 'expiresInS': 120});
    });
    var checkinCalls = 0;
    built.adapter.on('POST', '/v1/checkins', (options) {
      checkinCalls++;
      if (checkinCalls == 1) {
        return _jsonBody(410, {
          'error': {'code': 'checkin/nonce_expired', 'message': 'Nonce is missing, used, or expired'},
        });
      }
      return _jsonBody(201, {
        'checkin': {
          'id': 'c1',
          'poiId': 'poi1',
          'status': 'verified',
          'mode': 'confirm',
          'evidence': 'live',
          'createdAt': '2026-01-01T00:00:09.000Z',
          'verifiedAt': '2026-01-01T00:00:09.000Z',
        },
      });
    });
    final controller = _controller(built);

    await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

    expect(intentCalls, 2);
    expect(checkinCalls, 2);
    controller.state.maybeWhen(verified: (_) {}, orElse: () => fail('expected verified after retry'));
  });

  test('fewer than minFixes collected transitions to fixTimeout, never calls /checkins', () async {
    final built = _build(fixes: [_fixAt(0)]);
    _stubIntent(built.adapter);
    final controller = _controller(built);

    await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

    expect(controller.state, const CheckinState.fixTimeout());
    expect(built.adapter.requests.where((r) => r.path == '/v1/checkins'), isEmpty);
  });

  test('photo mode: face detected blocks before upload/submit', () async {
    final built = _build();
    built.faceGate.result = true;
    _stubIntent(built.adapter);
    final controller = _controller(built);
    final tempFile = File.fromUri(Directory.systemTemp.uri.resolve('checkin_test_photo.jpg'))
      ..writeAsBytesSync([1, 2, 3]);

    await controller.submit(
      poiId: 'poi1',
      deviceId: 'dev1',
      mode: 'photo',
      capturePhoto: (nonce) async => PendingCheckinPhoto(
        path: tempFile.path,
        capturedAt: DateTime.utc(2026, 1, 1, 0, 0, 9),
      ),
    );

    expect(controller.state, const CheckinState.photoBlocked());
    expect(built.uploader.uploadedUrls, isEmpty);
    expect(built.adapter.requests.where((r) => r.path == '/v1/checkins'), isEmpty);
  });

  test('photo mode: an undecodable photo transitions to photoProcessingFailed', () async {
    final built = _build();
    _stubIntent(built.adapter);
    final controller = _controller(built);
    final tempFile = File.fromUri(Directory.systemTemp.uri.resolve('checkin_test_bad_photo.jpg'))
      ..writeAsBytesSync([1, 2, 3]);

    await controller.submit(
      poiId: 'poi1',
      deviceId: 'dev1',
      mode: 'photo',
      capturePhoto: (nonce) async => PendingCheckinPhoto(
        path: tempFile.path,
        capturedAt: DateTime.utc(2026, 1, 1, 0, 0, 9),
      ),
    );

    expect(controller.state, const CheckinState.photoProcessingFailed());
    expect(built.uploader.uploadedUrls, isEmpty);
    expect(built.adapter.requests.where((r) => r.path == '/v1/checkins'), isEmpty);
  });

  test('photo mode happy path uploads then submits with a matching capture token', () async {
    final built = _build();
    _stubIntent(built.adapter, nonce: 'nonceABC');
    built.adapter.onJson('POST', '/v1/pois/poi1/photos/presign', 201, {
      'uploadUrl': 'https://storage.example/upload',
      'storageKey': 'photos/poi1/ph1.jpg',
      'maxBytes': 1048576,
    });
    built.adapter.onJson('POST', '/v1/pois/poi1/photos/complete', 201, {
      'photo': {
        'id': 'ph1',
        'urlCard': '/media/card/ph1',
        'urlThumb': '/media/thumb/ph1',
        'voteScore': 0,
        'myVote': false,
        'uploader': {'handle': 'explorer_x'},
        'status': 'pending',
      },
    });
    _stubCheckin(built.adapter, status: 'verified');
    final controller = _controller(built);
    final tempFile = File.fromUri(Directory.systemTemp.uri.resolve('checkin_test_photo2.jpg'))
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 10, height: 10)));
    final capturedAt = DateTime.utc(2026, 1, 1, 0, 0, 9);

    await controller.submit(
      poiId: 'poi1',
      deviceId: 'dev1',
      mode: 'photo',
      capturePhoto: (nonce) async => PendingCheckinPhoto(path: tempFile.path, capturedAt: capturedAt),
    );

    expect(built.uploader.uploadedUrls, ['https://storage.example/upload']);
    final submitBody = built.adapter.requests.last.data as Map<String, dynamic>;
    final capture = submitBody['capture'] as Map<String, dynamic>;
    expect(capture['storageKey'], 'photos/poi1/ph1.jpg');
    expect(
      capture['token'],
      sha256.convert(utf8.encode('nonceABC.${capturedAt.millisecondsSinceEpoch}')).toString(),
    );
    controller.state.maybeWhen(verified: (_) {}, orElse: () => fail('expected verified'));
  });

  test('photo mode: user cancels capture, returns to idle with no network side effects', () async {
    final built = _build();
    _stubIntent(built.adapter);
    final controller = _controller(built);

    await controller.submit(
      poiId: 'poi1',
      deviceId: 'dev1',
      mode: 'photo',
      capturePhoto: (nonce) async => null,
    );

    expect(controller.state, const CheckinState.idle());
    expect(built.uploader.uploadedUrls, isEmpty);
  });

  group('SPEC §17 — offline check-in outbox', () {
    void stubIntentNetworkFailure(FakeAdapter adapter) {
      adapter.on(
        'POST',
        '/v1/checkins/intent',
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
    }

    test('confirm mode: no connectivity at intent time queues fixes, no /checkins call', () async {
      final built = _build();
      stubIntentNetworkFailure(built.adapter);
      final controller = _controller(built);

      await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

      expect(controller.state, const CheckinState.queued());
      expect(built.adapter.requests.where((r) => r.path == '/v1/checkins'), isEmpty);
      final queued = await built.outbox.load();
      expect(queued, hasLength(1));
      expect(queued.single.poiId, 'poi1');
      expect(queued.single.mode, 'confirm');
      expect(queued.single.fixes, hasLength(2));
      expect(queued.single.photoPath, isNull);
    });

    test('photo mode: no connectivity at intent time still face-gates and resizes before queuing', () async {
      final built = _build();
      stubIntentNetworkFailure(built.adapter);
      final controller = _controller(built);
      final tempFile = File.fromUri(Directory.systemTemp.uri.resolve('checkin_outbox_photo.jpg'))
        ..writeAsBytesSync(img.encodeJpg(img.Image(width: 10, height: 10)));
      final capturedAt = DateTime.utc(2026, 1, 1, 0, 0, 9);

      await controller.submit(
        poiId: 'poi1',
        deviceId: 'dev1',
        mode: 'photo',
        capturePhoto: (nonce) async =>
            PendingCheckinPhoto(path: tempFile.path, capturedAt: capturedAt),
      );

      expect(controller.state, const CheckinState.queued());
      expect(built.faceGate.checkedPaths, [tempFile.path]);
      expect(built.uploader.uploadedUrls, isEmpty);
      final queued = await built.outbox.load();
      expect(queued, hasLength(1));
      expect(queued.single.mode, 'photo');
      expect(queued.single.photoPath, isNotNull);
      expect(File(queued.single.photoPath!).existsSync(), isTrue);
      expect(queued.single.photoCapturedAt, capturedAt);
    });

    test('photo mode: a face detected still blocks before queuing', () async {
      final built = _build();
      built.faceGate.result = true;
      stubIntentNetworkFailure(built.adapter);
      final controller = _controller(built);
      final tempFile =
          File.fromUri(Directory.systemTemp.uri.resolve('checkin_outbox_blocked.jpg'))
            ..writeAsBytesSync([1, 2, 3]);

      await controller.submit(
        poiId: 'poi1',
        deviceId: 'dev1',
        mode: 'photo',
        capturePhoto: (nonce) async => PendingCheckinPhoto(
          path: tempFile.path,
          capturedAt: DateTime.utc(2026, 1, 1, 0, 0, 9),
        ),
      );

      expect(controller.state, const CheckinState.photoBlocked());
      expect(await built.outbox.load(), isEmpty);
    });

    test('fewer than minFixes at intent-network-failure time still hits fixTimeout, nothing queued', () async {
      final built = _build(fixes: [_fixAt(0)]);
      stubIntentNetworkFailure(built.adapter);
      final controller = _controller(built);

      await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

      expect(controller.state, const CheckinState.fixTimeout());
      expect(await built.outbox.load(), isEmpty);
    });

    test('checkin/duplicate at intent time maps to duplicate, not queued', () async {
      final built = _build();
      built.adapter.onJson('POST', '/v1/checkins/intent', 409, {
        'error': {'code': 'checkin/duplicate', 'message': 'Already checked in at this POI'},
      });
      final controller = _controller(built);

      await controller.submit(poiId: 'poi1', deviceId: 'dev1', mode: 'confirm');

      expect(controller.state, const CheckinState.duplicate());
      expect(await built.outbox.load(), isEmpty);
    });
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
