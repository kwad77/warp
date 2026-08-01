import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import 'map_query.dart';
import 'map_view_state.dart';

/// SPEC §12 — fetches `GET /pois` for the current viewport; the widget debounces
/// camera-idle events before calling [load].
class MapController extends StateNotifier<MapViewState> {
  final WanderpostApi api;

  MapController(this.api) : super(const MapViewState());

  Future<void> load(BoundingBox bbox, double cameraZoom) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final result = await api.pois(
        west: bbox.west,
        south: bbox.south,
        east: bbox.east,
        north: bbox.north,
        zoom: zoomForQuery(cameraZoom),
      );
      state = state.copyWith(result: result, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    }
  }
}
