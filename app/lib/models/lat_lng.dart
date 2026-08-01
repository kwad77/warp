import 'package:freezed_annotation/freezed_annotation.dart';

part 'lat_lng.freezed.dart';

@freezed
class LatLng with _$LatLng {
  const factory LatLng({required double lat, required double lng}) = _LatLng;

  factory LatLng.fromMap(Map<String, dynamic> json) => LatLng(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}
