import 'package:freezed_annotation/freezed_annotation.dart';

part 'gps_fix.freezed.dart';

/// SPEC §7 `Fix = {lat, lng, accuracyM, capturedAt}`. `fromMap` exists only for the
/// offline check-in outbox (SPEC §17) round-tripping a queued fix through its local JSON
/// manifest — this is still never parsed from a server response.
@freezed
class GpsFix with _$GpsFix {
  const factory GpsFix({
    required double lat,
    required double lng,
    required double accuracyM,
    required DateTime capturedAt,
  }) = _GpsFix;

  const GpsFix._();

  factory GpsFix.fromMap(Map<String, dynamic> json) => GpsFix(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        accuracyM: (json['accuracyM'] as num).toDouble(),
        capturedAt: DateTime.parse(json['capturedAt'] as String),
      );

  /// `capturedAt` MUST be UTC with a trailing `Z` — the server's `z.string().datetime()`
  /// requires it (SPEC §7 `gpsFix`).
  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'accuracyM': accuracyM,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };
}
