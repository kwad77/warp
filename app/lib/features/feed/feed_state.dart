import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/poi_pin.dart';

part 'feed_state.freezed.dart';

/// SPEC §19 — "places around me" (`GET /pois/nearby`) and "places I want to visit"
/// (`GET /me/map`'s `saved`), client-merged. No public/social feed of other users'
/// activity — both sources are either already-public POI discovery data or the caller's
/// own bookmarks.
@freezed
class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<PoiPin> nearby,
    @Default([]) List<PoiPin> saved,
    @Default(false) bool loading,
    String? errorMessage,
  }) = _FeedState;
}
