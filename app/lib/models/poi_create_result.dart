import 'package:freezed_annotation/freezed_annotation.dart';

import 'poi.dart';
import 'poi_pin.dart';

part 'poi_create_result.freezed.dart';

/// SPEC §7 `POST /pois`: `201 {poi}` or `200 {dedupeCandidates}` — never both.
@freezed
class PoiCreateResult with _$PoiCreateResult {
  const factory PoiCreateResult.created(Poi poi) = _Created;
  const factory PoiCreateResult.dedupe(List<PoiPin> candidates) = _Dedupe;
}
