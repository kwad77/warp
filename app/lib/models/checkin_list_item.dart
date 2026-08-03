import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkin_list_item.freezed.dart';

/// SPEC §7 `GET /me/checkins`' `items[]`. Distinct from `Checkin` (the `POST /checkins` /
/// `GET /checkins/:id` shape) — this one carries `poiTitle`/`poiCategory` for a history
/// list, `Checkin` doesn't.
@freezed
class CheckinListItem with _$CheckinListItem {
  const factory CheckinListItem({
    required String id,
    required String poiId,
    required String poiTitle,
    required String poiCategory,
    required String status,
    required String mode,
    required String evidence,
    required String createdAt,
    String? verifiedAt,
  }) = _CheckinListItem;

  factory CheckinListItem.fromMap(Map<String, dynamic> json) => CheckinListItem(
        id: json['id'] as String,
        poiId: json['poiId'] as String,
        poiTitle: json['poiTitle'] as String,
        poiCategory: json['poiCategory'] as String,
        status: json['status'] as String,
        mode: json['mode'] as String,
        evidence: json['evidence'] as String,
        createdAt: json['createdAt'] as String,
        verifiedAt: json['verifiedAt'] as String?,
      );
}
