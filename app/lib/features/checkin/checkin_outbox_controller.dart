import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/device_store.dart';
import '../../core/hash.dart';
import '../../core/wanderpost_api.dart';
import '../poi/photo_uploader.dart';
import 'checkin_outbox.dart';
import 'checkin_outbox_state.dart';
import 'device_registrar.dart';
import 'integrity_token_provider.dart';

/// SPEC §17 — replays the offline check-in outbox opportunistically (app foreground/
/// launch, or a manual retry action; no background sync). Per item, in order queued:
/// fresh intent, (photo mode) presign/upload/complete now, then submit with the item's
/// true `fixes`/`capture.capturedAt` and `evidence: "deferred"`. A network failure OR a
/// rate limit (transient by definition — `CHECKIN_INTENT_PER_HOUR`, SPEC §2 — not a
/// verdict on this check-in) stops the whole replay pass and leaves every remaining item
/// queued, this one included; any other server-answered outcome (duplicate, rejected, …)
/// drops that one item — the server has already given its real verdict on it.
class CheckinOutboxController extends StateNotifier<CheckinOutboxState> {
  final WanderpostApi api;
  final CheckinOutbox outbox;
  final IntegrityTokenProvider integrityTokenProvider;
  final PhotoUploader uploader;
  final DeviceStore deviceStore;

  CheckinOutboxController({
    required this.api,
    required this.outbox,
    required this.integrityTokenProvider,
    required this.uploader,
    required this.deviceStore,
  }) : super(const CheckinOutboxState());

  Future<void> load() async {
    state = state.copyWith(items: await outbox.load());
  }

  Future<void> replay() async {
    if (state.replaying || state.items.isEmpty) return;
    state = state.copyWith(replaying: true);
    final deviceId = await ensureDeviceId(api, deviceStore);
    for (final item in List.of(state.items)) {
      final ageS = DateTime.now().difference(item.attemptedAt).inSeconds;
      if (ageS > AppConfig.checkinDeferredMaxAgeS) {
        await outbox.remove(item.id);
        continue;
      }
      try {
        final intent = await api.checkinIntent(poiId: item.poiId, deviceId: deviceId);
        ({String token, String capturedAt, String storageKey})? capture;
        final photoPath = item.photoPath;
        if (item.mode == 'photo' && photoPath != null) {
          final bytes = await File(photoPath).readAsBytes();
          final presigned = await api.presignPhoto(
            item.poiId,
            contentType: AppConfig.photoContentType,
            source: 'checkin',
          );
          await uploader.upload(
            presigned.uploadUrl,
            bytes,
            contentType: AppConfig.photoContentType,
          );
          await api.completePhoto(item.poiId, storageKey: presigned.storageKey, source: 'checkin');
          final capturedAtUtc = (item.photoCapturedAt ?? item.attemptedAt).toUtc();
          capture = (
            token: sha256Hex('${intent.nonce}.${capturedAtUtc.millisecondsSinceEpoch}'),
            capturedAt: capturedAtUtc.toIso8601String(),
            storageKey: presigned.storageKey,
          );
        }
        final integrityToken = await integrityTokenProvider.token(intent.nonce);
        await api.submitCheckin(
          nonce: intent.nonce,
          poiId: item.poiId,
          mode: item.mode,
          fixes: item.fixes,
          integrityToken: integrityToken,
          evidence: 'deferred',
          capture: capture,
        );
        await outbox.remove(item.id);
      } on ApiException catch (e) {
        if (retryLaterCodes.contains(e.code)) break;
        await outbox.remove(item.id);
      }
    }
    state = state.copyWith(items: await outbox.load(), replaying: false);
  }
}

/// Codes meaning "try the whole pass again later, don't drop anything" — as opposed to a
/// real verdict on this specific item. Shared with `PoiCreateOutboxController`.
const retryLaterCodes = {'network/unreachable', 'rate/limited'};
