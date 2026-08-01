import 'package:freezed_annotation/freezed_annotation.dart';

import 'lat_lng.dart';

part 'poi_pin.freezed.dart';

/// SPEC §7: `PoiPin = {id, title, category, location, checkinCount}`.
@freezed
class PoiPin with _$PoiPin {
  const factory PoiPin({
    required String id,
    required String title,
    required String category,
    required LatLng location,
    required int checkinCount,
  }) = _PoiPin;

  factory PoiPin.fromMap(Map<String, dynamic> json) => PoiPin(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        location: LatLng.fromMap(json['location'] as Map<String, dynamic>),
        checkinCount: json['checkinCount'] as int,
      );
}
