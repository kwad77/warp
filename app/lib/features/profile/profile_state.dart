import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/leaderboard_result.dart';
import '../../models/me_map.dart';
import '../../models/me_stats.dart';
import '../../models/user.dart';

part 'profile_state.freezed.dart';

/// SPEC §14 profile screen states.
@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.loaded({
    required User user,
    required MeStats stats,
    required MeMap poiMap,
    required int coverageCount,
    required LeaderboardResult leaderboard,
  }) = _Loaded;
  const factory ProfileState.error(String message) = _Error;
}
