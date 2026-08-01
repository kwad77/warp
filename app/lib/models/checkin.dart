import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkin.freezed.dart';

/// SPEC §7/§13.2: mirrors the server's `CheckinView` exactly.
@freezed
class Checkin with _$Checkin {
  const factory Checkin({
    required String id,
    required String poiId,
    required String status,
    required String mode,
    required String evidence,
    required String createdAt,
    String? verifiedAt,
  }) = _Checkin;

  factory Checkin.fromMap(Map<String, dynamic> json) => Checkin(
        id: json['id'] as String,
        poiId: json['poiId'] as String,
        status: json['status'] as String,
        mode: json['mode'] as String,
        evidence: json['evidence'] as String,
        createdAt: json['createdAt'] as String,
        verifiedAt: json['verifiedAt'] as String?,
      );
}
