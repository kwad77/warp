import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/hash.dart';
import '../../core/image_resize.dart';
import '../../core/wanderpost_api.dart';
import '../poi/face_gate.dart';
import '../poi/location_source.dart';
import '../poi/photo_uploader.dart';
import 'checkin_state.dart';
import 'fix_collector.dart';
import 'integrity_token_provider.dart';
import 'pending_checkin_photo.dart';

/// SPEC §5/§13.2 — drives intent → fix gathering → (photo mode) capture/upload → submit.
/// `capturePhoto` is supplied by the screen (it owns navigation to the camera); the
/// controller only decides what happens with the result, keeping this unit-testable.
class CheckinController extends StateNotifier<CheckinState> {
  final WanderpostApi api;
  final LocationSource locationSource;
  final IntegrityTokenProvider integrityTokenProvider;
  final FaceGate faceGate;
  final PhotoUploader uploader;

  CheckinController({
    required this.api,
    required this.locationSource,
    required this.integrityTokenProvider,
    required this.faceGate,
    required this.uploader,
  }) : super(const CheckinState.idle());

  /// Back to mode choice from any terminal state (`rejected`/`fixTimeout`/`error`).
  void resetToIdle() {
    state = const CheckinState.idle();
  }

  Future<void> submit({
    required String poiId,
    required String deviceId,
    required String mode,
    Future<PendingCheckinPhoto?> Function(String nonce)? capturePhoto,
  }) {
    return _submit(
      poiId: poiId,
      deviceId: deviceId,
      mode: mode,
      capturePhoto: capturePhoto,
      isRetry: false,
    );
  }

  Future<void> _submit({
    required String poiId,
    required String deviceId,
    required String mode,
    required Future<PendingCheckinPhoto?> Function(String nonce)? capturePhoto,
    required bool isRetry,
  }) async {
    state = const CheckinState.inProgress();
    try {
      final intent = await api.checkinIntent(poiId: poiId, deviceId: deviceId);

      final fixes = await collectFixes(
        locationSource.fixStream().timeout(Duration(seconds: AppConfig.fixWindowMaxS + 10)),
        minFixes: AppConfig.minFixes,
        maxFixes: AppConfig.maxFixes,
        minSpan: Duration(seconds: AppConfig.fixSpanMinS),
        maxWindow: Duration(seconds: AppConfig.fixWindowMaxS),
      );
      if (fixes.length < AppConfig.minFixes) {
        state = const CheckinState.fixTimeout();
        return;
      }

      ({String token, String capturedAt, String storageKey})? capture;
      if (mode == 'photo') {
        final photo = capturePhoto == null ? null : await capturePhoto(intent.nonce);
        if (photo == null) {
          state = const CheckinState.idle();
          return;
        }
        final hasFace = await faceGate.hasFace(photo.path);
        if (hasFace) {
          state = const CheckinState.photoBlocked();
          return;
        }
        final rawBytes = await File(photo.path).readAsBytes();
        final resizedBytes = resizeForUpload(
          rawBytes,
          maxLongEdge: AppConfig.uploadMaxLongEdgePx,
          maxBytes: AppConfig.uploadMaxBytes,
        );
        if (resizedBytes == null) {
          state = const CheckinState.photoProcessingFailed();
          return;
        }
        final presigned = await api.presignPhoto(
          poiId,
          contentType: AppConfig.photoContentType,
          source: 'checkin',
        );
        await uploader.upload(presigned.uploadUrl, resizedBytes, contentType: AppConfig.photoContentType);
        await api.completePhoto(poiId, storageKey: presigned.storageKey, source: 'checkin');
        final capturedAtUtc = photo.capturedAt.toUtc();
        capture = (
          token: sha256Hex('${intent.nonce}.${capturedAtUtc.millisecondsSinceEpoch}'),
          capturedAt: capturedAtUtc.toIso8601String(),
          storageKey: presigned.storageKey,
        );
      }

      final integrityToken = await integrityTokenProvider.token(intent.nonce);

      final checkin = await api.submitCheckin(
        nonce: intent.nonce,
        poiId: poiId,
        mode: mode,
        fixes: fixes,
        integrityToken: integrityToken,
        capture: capture,
      );
      state = checkin.status == 'verified'
          ? CheckinState.verified(checkin)
          : CheckinState.pending(checkin);
    } on ApiException catch (e) {
      if (e.code == 'checkin/nonce_expired' && !isRetry) {
        await _submit(
          poiId: poiId,
          deviceId: deviceId,
          mode: mode,
          capturePhoto: capturePhoto,
          isRetry: true,
        );
        return;
      }
      state = switch (e.code) {
        'checkin/duplicate' => const CheckinState.duplicate(),
        'checkin/rejected' => CheckinState.rejected(
            (e.details?['reasons'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
          ),
        _ => CheckinState.error(e.message),
      };
    }
  }
}
