import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/poi/face_gate.dart';
import 'package:wanderpost/features/poi/pending_photo.dart';
import 'package:wanderpost/features/poi/photo_uploader.dart';
import 'package:wanderpost/features/poi/poi_create_controller.dart';
import 'package:wanderpost/features/poi/poi_create_state.dart';
import 'package:wanderpost/models/gps_fix.dart';
import 'package:wanderpost/models/lat_lng.dart';
import 'package:wanderpost/models/poi_pin.dart';

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

final _gpsFix = GpsFix(lat: 1.0, lng: 2.0, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1));
const _location = LatLng(lat: 1.0001, lng: 2.0001);

({
  WanderpostApi api,
  FakeAdapter adapter,
  _FakeFaceGate faceGate,
  _FakePhotoUploader uploader,
}) _build() {
  final adapter = FakeAdapter();
  final api = WanderpostApi(
    ApiClient(
      baseUrl: 'http://test',
      tokenStore: TokenStore(storage: _InMemorySecureStore()),
      dio: buildFakeDio(adapter),
    ),
  );
  return (api: api, adapter: adapter, faceGate: _FakeFaceGate(), uploader: _FakePhotoUploader());
}

PoiCreateController _controller(
  ({
    WanderpostApi api,
    FakeAdapter adapter,
    _FakeFaceGate faceGate,
    _FakePhotoUploader uploader,
  }) built,
) =>
    PoiCreateController(api: built.api, faceGate: built.faceGate, uploader: built.uploader);

void main() {
  test('starts editing', () {
    final built = _build();
    final controller = _controller(built);
    expect(controller.state, const PoiCreateState.editing());
  });

  test('submit success with no photo transitions to created, no upload calls', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/pois', 201, {
      'poi': {
        'id': 'poi1',
        'title': 'Torre',
        'category': 'landmark',
        'location': {'lat': 1.0001, 'lng': 2.0001},
        'checkinCount': 0,
        'description': null,
        'creator': {'id': 'u1', 'handle': 'explorer_x'},
        'checkinRadiusM': 75,
        'gallery': <Map<String, dynamic>>[],
      },
    });
    final controller = _controller(built);

    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );

    expect(controller.state, isA<PoiCreateState>());
    controller.state.when(
      editing: () => fail('expected created'),
      submitting: () => fail('expected created'),
      created: (poi) => expect(poi.id, 'poi1'),
      dedupe: (_) => fail('expected created'),
      pinAdjustError: () => fail('expected created'),
      photoBlocked: () => fail('expected created'),
      error: (_) => fail('expected created'),
    );
    expect(built.uploader.uploadedUrls, isEmpty);
    final sentBody = built.adapter.requests.single.data as Map<String, dynamic>;
    expect(sentBody['gpsFix'], {
      'lat': 1.0,
      'lng': 2.0,
      'accuracyM': 10.0,
      'capturedAt': '2026-01-01T00:00:00.000Z',
    });
  });

  test('dedupeCandidates response transitions to dedupe', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/pois', 200, {
      'dedupeCandidates': [
        {
          'id': 'p1',
          'title': 'Existing',
          'category': 'landmark',
          'location': {'lat': 1.0, 'lng': 2.0},
          'checkinCount': 3,
        },
      ],
    });
    final controller = _controller(built);

    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );

    expect(
      controller.state,
      PoiCreateState.dedupe([
        const PoiPin(
          id: 'p1',
          title: 'Existing',
          category: 'landmark',
          location: LatLng(lat: 1.0, lng: 2.0),
          checkinCount: 3,
        ),
      ]),
    );
  });

  test('forceCreateAnyway resubmits the last payload with force: true', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/pois', 200, {
      'dedupeCandidates': <Map<String, dynamic>>[],
    });
    final controller = _controller(built);
    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    expect(built.adapter.requests, hasLength(1));
    expect(built.adapter.requests.single.data['force'], isNull);

    built.adapter.onJson('POST', '/v1/pois', 201, {
      'poi': {
        'id': 'poi1',
        'title': 'Torre',
        'category': 'landmark',
        'location': {'lat': 1.0001, 'lng': 2.0001},
        'checkinCount': 0,
        'description': null,
        'creator': {'id': 'u1', 'handle': 'explorer_x'},
        'checkinRadiusM': 75,
        'gallery': <Map<String, dynamic>>[],
      },
    });

    await controller.forceCreateAnyway();

    expect(built.adapter.requests, hasLength(2));
    expect(built.adapter.requests.last.data['force'], true);
    expect(controller.state, isA<PoiCreateState>());
  });

  test('poi/outside_pin_adjust transitions to pinAdjustError, not the generic error', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/pois', 422, {
      'error': {'code': 'poi/outside_pin_adjust', 'message': 'Pin too far from GPS fix'},
    });
    final controller = _controller(built);

    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );

    expect(controller.state, const PoiCreateState.pinAdjustError());
  });

  test('any other server error transitions to error(message)', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/pois', 429, {
      'error': {'code': 'rate/limited', 'message': 'Too many POIs created today'},
    });
    final controller = _controller(built);

    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );

    expect(controller.state, const PoiCreateState.error('Too many POIs created today'));
  });

  test('a detected face blocks before any network call', () async {
    final built = _build();
    built.faceGate.result = true;
    final controller = _controller(built);

    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
      photo: const PendingPhoto(path: '/tmp/photo.jpg', contentType: 'image/jpeg'),
    );

    expect(controller.state, const PoiCreateState.photoBlocked());
    expect(built.adapter.requests, isEmpty);
    expect(built.faceGate.checkedPaths, ['/tmp/photo.jpg']);
  });

  test('resetToEditing returns to editing from any terminal state', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/pois', 429, {
      'error': {'code': 'rate/limited', 'message': 'Too many POIs created today'},
    });
    final controller = _controller(built);
    await controller.submit(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    expect(controller.state, isA<PoiCreateState>());

    controller.resetToEditing();

    expect(controller.state, const PoiCreateState.editing());
  });
}
