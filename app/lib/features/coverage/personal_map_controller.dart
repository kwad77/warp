import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import '../../models/me_map.dart';
import '../map/map_query.dart';
import 'personal_map_state.dart';

/// SPEC §15 — below the pin-mode zoom threshold (13, shared with `GET /pois`'s existing
/// cluster/pin split), fetches the coverage heatmap; at/above it, switches to individual
/// pins from two existing endpoints (`GET /me/map`'s `checkedIn`, `GET /pois`) rather than
/// a new one. `GET /me/map` returns the caller's entire history unfiltered by viewport, so
/// it's fetched once and cached, then re-filtered to each new bbox client-side —
/// `GET /pois` (bbox-aware already) is still re-fetched per viewport.
class PersonalMapController extends StateNotifier<PersonalMapState> {
  final WanderpostApi api;
  MeMap? _cachedMeMap;

  PersonalMapController(this.api) : super(const PersonalMapState());

  Future<void> load(BoundingBox bbox, double cameraZoom) async {
    state = state.copyWith(loading: true, errorMessage: null);
    final zoom = zoomForQuery(cameraZoom);
    try {
      if (zoom >= 13) {
        _cachedMeMap ??= await api.meMap();
        final poisResult = await api.pois(
          west: bbox.west,
          south: bbox.south,
          east: bbox.east,
          north: bbox.north,
          zoom: zoom,
        );
        final visiblePostcards =
            _cachedMeMap!.checkedIn.where((p) => bbox.contains(p.location)).toList();
        state = state.copyWith(
          mode: PersonalMapMode.pins,
          myPostcards: visiblePostcards,
          nearbyPois: poisResult.pois,
          loading: false,
        );
      } else {
        final heatmap = await api.coverageHeatmap(zoom: zoom);
        state = state.copyWith(
          mode: PersonalMapMode.heatmap,
          heatmapCells: heatmap.cells,
          loading: false,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    }
  }
}
