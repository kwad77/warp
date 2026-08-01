import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/wanderpost_api.dart';
import '../../models/queued_poi_creation.dart';
import '../checkin/checkin_outbox_controller.dart' show retryLaterCodes;
import 'photo_uploader.dart';
import 'poi_create_outbox.dart';
import 'poi_create_outbox_state.dart';

/// SPEC §18 — replays the offline POI-creation outbox opportunistically (same triggers
/// as §17's check-in outbox: app launch, manual retry, no background sync). Per item:
/// `POST /pois` with `force: false`; a `dedupeCandidates` response is automatically
/// resubmitted with `force: true` (no human present at replay time to pick a candidate —
/// SPEC §18's flagged choice), then (if a photo was queued) presign/upload/complete it,
/// swallowing a failure there exactly as the live flow already does. A network failure or
/// `rate/limited` stops the whole pass, same rule §17 uses; any other server-answered
/// outcome drops that one item.
class PoiCreateOutboxController extends StateNotifier<PoiCreateOutboxState> {
  final WanderpostApi api;
  final PoiCreateOutbox outbox;
  final PhotoUploader uploader;

  PoiCreateOutboxController({
    required this.api,
    required this.outbox,
    required this.uploader,
  }) : super(const PoiCreateOutboxState());

  Future<void> load() async {
    state = state.copyWith(items: await outbox.load());
  }

  Future<void> replay() async {
    if (state.replaying || state.items.isEmpty) return;
    state = state.copyWith(replaying: true);
    for (final item in List.of(state.items)) {
      try {
        final poiId = await _createWithAutoForce(item);
        if (poiId != null) {
          final photoPath = item.photoPath;
          if (photoPath != null) {
            await _uploadPhoto(poiId, photoPath);
          }
          await outbox.remove(item.id);
        } else {
          // force: true still came back as dedupe — shouldn't happen (force skips the
          // dedupe check server-side), but drop rather than retry forever on something
          // that will never resolve differently.
          await outbox.remove(item.id);
        }
      } on ApiException catch (e) {
        if (retryLaterCodes.contains(e.code)) break;
        await outbox.remove(item.id);
      }
    }
    state = state.copyWith(items: await outbox.load(), replaying: false);
  }

  Future<String?> _createWithAutoForce(QueuedPoiCreation item) async {
    final result = await api.createPoi(
      title: item.title,
      description: item.description,
      category: item.category,
      location: item.location,
      gpsFix: item.gpsFix,
    );
    return result.when(
      created: (poi) async => poi.id,
      dedupe: (_) async {
        final forced = await api.createPoi(
          title: item.title,
          description: item.description,
          category: item.category,
          location: item.location,
          gpsFix: item.gpsFix,
          force: true,
        );
        return forced.when(created: (poi) async => poi.id, dedupe: (_) async => null);
      },
    );
  }

  /// A failed upload does NOT undo the already-created POI, matching the live flow's own
  /// `PoiCreateController._uploadPhoto` (SPEC §13.1) — the detail screen's retry
  /// affordance is unchanged, so failures here are swallowed rather than re-queued.
  Future<void> _uploadPhoto(String poiId, String photoPath) async {
    try {
      final bytes = await File(photoPath).readAsBytes();
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
