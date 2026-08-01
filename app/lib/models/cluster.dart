import 'package:freezed_annotation/freezed_annotation.dart';

import 'lat_lng.dart';

part 'cluster.freezed.dart';

/// SPEC §7: `Cluster = {h3, count, centroid: {lat, lng}}`.
@freezed
class Cluster with _$Cluster {
  const factory Cluster({
    required String h3,
    required int count,
    required LatLng centroid,
  }) = _Cluster;

  factory Cluster.fromMap(Map<String, dynamic> json) => Cluster(
        h3: json['h3'] as String,
        count: json['count'] as int,
        centroid: LatLng.fromMap(json['centroid'] as Map<String, dynamic>),
      );
}
