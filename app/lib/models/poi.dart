import 'package:freezed_annotation/freezed_annotation.dart';

import 'lat_lng.dart';
import 'photo.dart';

part 'poi.freezed.dart';

/// SPEC §7: full `Poi` — `PoiPin` fields plus description, creator, radius, gallery.
/// `creatorId`/`creatorHandle` are `null` when the POI is unclaimed (§21, M2) — seeded,
/// no real founder yet until the first approved photo on it claims it.
@freezed
class Poi with _$Poi {
  const factory Poi({
    required String id,
    required String title,
    required String category,
    required LatLng location,
    required int checkinCount,
    String? description,
    String? creatorId,
    String? creatorHandle,
    required int checkinRadiusM,
    required List<Photo> gallery,
  }) = _Poi;

  factory Poi.fromMap(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    return Poi(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      location: LatLng.fromMap(json['location'] as Map<String, dynamic>),
      checkinCount: json['checkinCount'] as int,
      description: json['description'] as String?,
      creatorId: creator?['id'] as String?,
      creatorHandle: creator?['handle'] as String?,
      checkinRadiusM: json['checkinRadiusM'] as int,
      gallery: (json['gallery'] as List<dynamic>)
          .map((e) => Photo.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
