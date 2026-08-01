import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/pois_result.dart';

part 'map_view_state.freezed.dart';

@freezed
class MapViewState with _$MapViewState {
  const factory MapViewState({
    @Default(PoisResult(pois: [], clusters: [])) PoisResult result,
    @Default(false) bool loading,
    String? errorMessage,
  }) = _MapViewState;
}
