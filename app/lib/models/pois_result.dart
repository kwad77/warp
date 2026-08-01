import 'package:freezed_annotation/freezed_annotation.dart';

import 'cluster.dart';
import 'poi_pin.dart';

part 'pois_result.freezed.dart';

/// SPEC §7 `GET /pois`: exactly one of `pois`/`clusters` is non-empty, never both.
@freezed
class PoisResult with _$PoisResult {
  const factory PoisResult({
    required List<PoiPin> pois,
    required List<Cluster> clusters,
  }) = _PoisResult;

  factory PoisResult.fromMap(Map<String, dynamic> json) => PoisResult(
        pois: (json['pois'] as List<dynamic>)
            .map((e) => PoiPin.fromMap(e as Map<String, dynamic>))
            .toList(),
        clusters: (json['clusters'] as List<dynamic>)
            .map((e) => Cluster.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}
