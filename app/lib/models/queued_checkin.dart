import 'package:freezed_annotation/freezed_annotation.dart';

import 'gps_fix.dart';

part 'queued_checkin.freezed.dart';

/// SPEC §17 — a check-in attempted with no connectivity, captured locally and awaiting
/// replay. `photoPath` (if present) points at a copy already made in the outbox's own
/// directory, already resized for upload (same processing the live path does before it
/// ever touches the network) — replay only has to presign/upload/complete it, not
/// reprocess it. `attemptedAt` is the moment the user tried to check in (not `capturedAt`
/// on any individual fix) — the bound `CHECKIN_DEFERRED_MAX_AGE_S` client-side drop check
/// (§17) is measured from it.
@freezed
class QueuedCheckin with _$QueuedCheckin {
  const factory QueuedCheckin({
    required String id,
    required String poiId,
    required String mode,
    required List<GpsFix> fixes,
    required DateTime attemptedAt,
    String? photoPath,
    DateTime? photoCapturedAt,
  }) = _QueuedCheckin;

  const QueuedCheckin._();

  factory QueuedCheckin.fromMap(Map<String, dynamic> json) => QueuedCheckin(
        id: json['id'] as String,
        poiId: json['poiId'] as String,
        mode: json['mode'] as String,
        fixes: (json['fixes'] as List<dynamic>)
            .map((e) => GpsFix.fromMap(e as Map<String, dynamic>))
            .toList(),
        attemptedAt: DateTime.parse(json['attemptedAt'] as String),
        photoPath: json['photoPath'] as String?,
        photoCapturedAt: json['photoCapturedAt'] != null
            ? DateTime.parse(json['photoCapturedAt'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'poiId': poiId,
        'mode': mode,
        'fixes': fixes.map((f) => f.toMap()).toList(),
        'attemptedAt': attemptedAt.toUtc().toIso8601String(),
        if (photoPath != null) 'photoPath': photoPath,
        if (photoCapturedAt != null)
          'photoCapturedAt': photoCapturedAt!.toUtc().toIso8601String(),
      };
}
