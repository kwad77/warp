import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/hash.dart';
import '../../core/image_resize.dart';
import '../../core/wanderpost_api.dart';
import '../poi/face_gate.dart';
import '../poi/location_source.dart';
import '../poi/photo_uploader.dart';
import 'checkin_outbox.dart';
import 'checkin_state.dart';
import 'fix_collector.dart';
import 'integrity_token_provider.dart';
import 'pending_checkin_photo.dart';

/// SPEC §5/§13.2/§17 — drives intent → fix gathering → (photo mode) capture/upload →
/// submit. `capturePhoto` is supplied by the screen (it owns navigation to the camera);
/// the controller only decides what happens with the result, keeping this unit-testable.
/// SPEC §17: if `checkinIntent` itself fails with no connectivity, falls back to
/// gathering fixes/photo locally (neither needs the network) and queuing in the offline
/// outbox instead of surfacing an error — the realistic "no signal at all" case. A
/// network failure later in the flow (fix gathering already succeeded, intent didn't) is
/// out of scope for this fallback and still surfaces as `CheckinState.error`.
class CheckinController extends StateNotifier<CheckinState> {
  final WanderpostApi api;
  final LocationSource locationSource;
  final IntegrityTokenProvider integrityTokenProvider;
  final FaceGate faceGate;
  final PhotoUploader uploader;
  final CheckinOutbox outbox;

  CheckinController({
    required this.api,
    required this.locationSource,
    required this.integrityTokenProvider,
    required this.faceGate,
    required this.uploader,
    required this.outbox,
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
    final attemptedAt = DateTime.now();
    ({String nonce, int expiresInS}) intent;
    try {
      intent = await api.checkinIntent(poiId: poiId, deviceId: deviceId);
    } on ApiException catch (e) {
      if (e.code == 'network/unreachable') {
        await _queueOffline(poiId: poiId, mode: mode, capturePhoto: capturePhoto, attemptedAt: attemptedAt);
        return;
      }
      state = switch (e.code) {
        'checkin/duplicate' => const CheckinState.duplicate(),
        _ => CheckinState.error(e.message),
      };
      return;
    }
    try {
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

  /// SPEC §17 — `checkinIntent` failed with no connectivity: gather everything that
  /// doesn't need the network (fixes, and photo mode's capture/face-gate/resize) and
  /// queue it, rather than surfacing an error for something the user has no way to fix
  /// right now.
  Future<void> _queueOffline({
    required String poiId,
    required String mode,
    required Future<PendingCheckinPhoto?> Function(String nonce)? capturePhoto,
    required DateTime attemptedAt,
  }) async {
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

    Uint8List? photoBytes;
    DateTime? photoCapturedAt;
    if (mode == 'photo') {
      // No nonce exists yet (offline) — the callback's `nonce` param goes unused either
      // way (see CameraCaptureScreen), so a placeholder is fine here.
      final photo = capturePhoto == null ? null : await capturePhoto('offline');
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
      photoBytes = resizedBytes;
      photoCapturedAt = photo.capturedAt;
    }

    await outbox.add(
      poiId: poiId,
      mode: mode,
      fixes: fixes,
      attemptedAt: attemptedAt,
      photoBytes: photoBytes,
      photoCapturedAt: photoCapturedAt,
    );
    state = const CheckinState.queued();
  }
}
