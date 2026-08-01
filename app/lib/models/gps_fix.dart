import 'package:freezed_annotation/freezed_annotation.dart';

part 'gps_fix.freezed.dart';

/// SPEC §7 `Fix = {lat, lng, accuracyM, capturedAt}` — sent to the server, never parsed
/// from one, so this only needs [toMap], not `fromMap`.
@freezed
class GpsFix with _$GpsFix {
  const factory GpsFix({
    required double lat,
    required double lng,
    required double accuracyM,
    required DateTime capturedAt,
  }) = _GpsFix;

  const GpsFix._();

  /// `capturedAt` MUST be UTC with a trailing `Z` — the server's `z.string().datetime()`
  /// requires it (SPEC §7 `gpsFix`).
  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'accuracyM': accuracyM,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };
}
