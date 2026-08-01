import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/image_resize.dart';
import '../../core/wanderpost_api.dart';
import '../../models/lat_lng.dart';
import '../../models/gps_fix.dart';
import 'pending_photo.dart';
import 'face_gate.dart';
import 'photo_uploader.dart';
import 'poi_create_state.dart';

/// SPEC §13.1 — drives `POST /pois` and the optional photo upload that follows a `201`.
/// The face-detection gate runs before any network call, for both the camera and gallery
/// paths (SPEC §6).
class PoiCreateController extends StateNotifier<PoiCreateState> {
  final WanderpostApi api;
  final FaceGate faceGate;
  final PhotoUploader uploader;

  ({
    String title,
    String? description,
    String category,
    LatLng location,
    GpsFix gpsFix,
    PendingPhoto? photo,
  })? _lastSubmission;

  PoiCreateController({
    required this.api,
    required this.faceGate,
    required this.uploader,
  }) : super(const PoiCreateState.editing());

  Future<void> submit({
    required String title,
    String? description,
    required String category,
    required LatLng location,
    required GpsFix gpsFix,
    PendingPhoto? photo,
  }) async {
    _lastSubmission = (
      title: title,
      description: description,
      category: category,
      location: location,
      gpsFix: gpsFix,
      photo: photo,
    );
    await _submit(force: false);
  }

  /// "None of these — create mine" from the dedupe picker: resubmits the same payload
  /// with `force: true`, skipping the server's dedupe prompt (SPEC §7/§13.1).
  Future<void> forceCreateAnyway() async {
    if (_lastSubmission == null) return;
    await _submit(force: true);
  }

  /// Back to the form from `pinAdjustError`/`error`/`photoBlocked`.
  void resetToEditing() {
    state = const PoiCreateState.editing();
  }

  Future<void> _submit({required bool force}) async {
    final submission = _lastSubmission!;
    Uint8List? resizedPhotoBytes;
    if (submission.photo != null) {
      final hasFace = await faceGate.hasFace(submission.photo!.path);
      if (hasFace) {
        state = const PoiCreateState.photoBlocked();
        return;
      }
      final rawBytes = await File(submission.photo!.path).readAsBytes();
      resizedPhotoBytes = resizeForUpload(rawBytes, maxLongEdge: AppConfig.uploadMaxLongEdgePx);
      if (resizedPhotoBytes == null) {
        state = const PoiCreateState.photoProcessingFailed();
        return;
      }
    }
    state = const PoiCreateState.submitting();
    try {
      final result = await api.createPoi(
        title: submission.title,
        description: submission.description,
        category: submission.category,
        location: submission.location,
        gpsFix: submission.gpsFix,
        force: force,
      );
      await result.when(
        created: (poi) async {
          if (resizedPhotoBytes != null) {
            await _uploadPhoto(poi.id, resizedPhotoBytes);
          }
          state = PoiCreateState.created(poi);
        },
        dedupe: (candidates) async {
          state = PoiCreateState.dedupe(candidates);
        },
      );
    } on ApiException catch (e) {
      state = e.code == 'poi/outside_pin_adjust'
          ? const PoiCreateState.pinAdjustError()
          : PoiCreateState.error(e.message);
    }
  }

  /// A failed upload does NOT undo the already-created POI (SPEC §13.1) — the detail
  /// screen offers its own retry, so failures here are swallowed rather than surfaced as
  /// a creation error.
  Future<void> _uploadPhoto(String poiId, Uint8List bytes) async {
    try {
      final presigned = await api.presignPhoto(
        poiId,
        contentType: AppConfig.photoContentType,
        source: 'poi_creation',
      );
      await uploader.upload(presigned.uploadUrl, bytes, contentType: AppConfig.photoContentType);
      await api.completePhoto(poiId, storageKey: presigned.storageKey, source: 'poi_creation');
    } on ApiException {
      // Swallowed — see doc comment.
    }
  }
}
