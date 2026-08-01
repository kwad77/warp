import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/coverage_heatmap_cell.dart';
import '../../models/poi_pin.dart';

part 'personal_map_state.freezed.dart';

/// SPEC §15 — heatmap at coarse zoom, individual pins (own postcards + nearby POIs) once
/// zoomed in past the pin-mode threshold shared with the discovery map.
enum PersonalMapMode { heatmap, pins }

@freezed
class PersonalMapState with _$PersonalMapState {
  const factory PersonalMapState({
    @Default(PersonalMapMode.heatmap) PersonalMapMode mode,
    @Default([]) List<CoverageHeatmapCell> heatmapCells,
    @Default([]) List<PoiPin> myPostcards,
    @Default([]) List<PoiPin> nearbyPois,
    @Default(false) bool loading,
    String? errorMessage,
  }) = _PersonalMapState;
}
