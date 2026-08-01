import 'package:freezed_annotation/freezed_annotation.dart';

import 'gps_fix.dart';
import 'lat_lng.dart';

part 'queued_poi_creation.freezed.dart';

/// SPEC §18 — a POI creation attempted with no connectivity, captured locally and
/// awaiting replay. Unlike `QueuedCheckin` (SPEC §17), there's no `attemptedAt`/age bound:
/// nothing server-side depends on how old `gpsFix` is (only its lat/lng, for the
/// `PIN_ADJUST_MAX_M` distance check), so nothing client-side needs to preemptively drop
/// it either. `photoPath`, if present, already points at an already face-gated and
/// resized copy in the outbox's own directory — same as `QueuedCheckin`.
@freezed
class QueuedPoiCreation with _$QueuedPoiCreation {
  const factory QueuedPoiCreation({
    required String id,
    required String title,
    String? description,
    required String category,
    required LatLng location,
    required GpsFix gpsFix,
    String? photoPath,
  }) = _QueuedPoiCreation;

  const QueuedPoiCreation._();

  factory QueuedPoiCreation.fromMap(Map<String, dynamic> json) => QueuedPoiCreation(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String,
        location: LatLng.fromMap(json['location'] as Map<String, dynamic>),
        gpsFix: GpsFix.fromMap(json['gpsFix'] as Map<String, dynamic>),
        photoPath: json['photoPath'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'category': category,
        'location': {'lat': location.lat, 'lng': location.lng},
        'gpsFix': gpsFix.toMap(),
        if (photoPath != null) 'photoPath': photoPath,
      };
}
