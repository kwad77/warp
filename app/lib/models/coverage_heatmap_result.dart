import 'package:freezed_annotation/freezed_annotation.dart';

import 'coverage_heatmap_cell.dart';

part 'coverage_heatmap_result.freezed.dart';

/// SPEC §15 `GET /me/coverage/heatmap`. `resolution` is `null` at/above the pin-mode
/// zoom threshold (13) — the caller should be using `GET /me/map` + `GET /pois` instead.
@freezed
class CoverageHeatmapResult with _$CoverageHeatmapResult {
  const factory CoverageHeatmapResult({
    required List<CoverageHeatmapCell> cells,
    int? resolution,
  }) = _CoverageHeatmapResult;

  factory CoverageHeatmapResult.fromMap(Map<String, dynamic> json) => CoverageHeatmapResult(
        cells: (json['cells'] as List<dynamic>)
            .map((e) => CoverageHeatmapCell.fromMap(e as Map<String, dynamic>))
            .toList(),
        resolution: json['resolution'] as int?,
      );
}
