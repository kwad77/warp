import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import '../../models/poi_pin.dart';
import '../poi/location_source.dart';
import 'feed_state.dart';

/// SPEC §19 — loads nearby POIs (centered on the device's current location) and the
/// caller's saved list, and drives the save/unsave toggle each feed card exposes.
class FeedController extends StateNotifier<FeedState> {
  final WanderpostApi api;
  final LocationSource locationSource;

  FeedController({required this.api, required this.locationSource}) : super(const FeedState());

  Future<void> load() async {
    state = state.copyWith(loading: true, errorMessage: null);
    List<PoiPin> nearby = const [];
    String? errorMessage;
    try {
      final fix = await locationSource.currentFix();
      nearby = await api.nearby(lat: fix.lat, lng: fix.lng);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = "Couldn't get your location.";
    }
    // Saved is the caller's own list (needs auth) — fetched separately so a logged-out
    // visitor still sees "places around me" instead of the whole feed erroring out.
    List<PoiPin> saved = state.saved;
    try {
      saved = (await api.meMap()).saved;
    } on ApiException {
      saved = const [];
    }
    state = state.copyWith(
      nearby: nearby,
      saved: saved,
      loading: false,
      errorMessage: errorMessage,
    );
  }

  Future<void> toggleSaved(String poiId) async {
    final isSaved = state.saved.any((p) => p.id == poiId);
    final candidates = [...state.nearby, ...state.saved].where((p) => p.id == poiId);
    if (candidates.isEmpty) return;
    final target = candidates.first;
    try {
      await api.setSavedPoi(poiId, save: !isSaved);
      state = state.copyWith(
        saved: isSaved
            ? state.saved.where((p) => p.id != poiId).toList()
            : [target, ...state.saved],
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}
