import 'package:freezed_annotation/freezed_annotation.dart';

import 'lat_lng.dart';

part 'coverage_heatmap_cell.freezed.dart';

/// SPEC §15 `GET /me/coverage/heatmap`'s `cells[]`.
@freezed
class CoverageHeatmapCell with _$CoverageHeatmapCell {
  const factory CoverageHeatmapCell({
    required String h3,
    required int count,
    required LatLng centroid,
  }) = _CoverageHeatmapCell;

  factory CoverageHeatmapCell.fromMap(Map<String, dynamic> json) => CoverageHeatmapCell(
        h3: json['h3'] as String,
        count: json['count'] as int,
        centroid: LatLng.fromMap(json['centroid'] as Map<String, dynamic>),
      );
}
