import 'package:freezed_annotation/freezed_annotation.dart';

import 'lat_lng.dart';

part 'poi_pin.freezed.dart';

/// SPEC §7: `PoiPin = {id, title, category, location, checkinCount, thumbnailUrl}`.
/// `thumbnailUrl` (SPEC §19, M2) is `null` where the server didn't compute it (e.g. the
/// bbox discovery endpoint) as well as where the POI genuinely has no approved photo —
/// the two cases render identically (a category-icon placeholder), so nothing needs to
/// distinguish them client-side.
@freezed
class PoiPin with _$PoiPin {
  const factory PoiPin({
    required String id,
    required String title,
    required String category,
    required LatLng location,
    required int checkinCount,
    String? thumbnailUrl,
  }) = _PoiPin;

  factory PoiPin.fromMap(Map<String, dynamic> json) => PoiPin(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        location: LatLng.fromMap(json['location'] as Map<String, dynamic>),
        checkinCount: json['checkinCount'] as int,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}
