import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import 'profile_state.dart';

/// SPEC §14 — loads `/me`, `/me/map`, `/me/coverage`, and the weekly coverage leaderboard.
/// Each call is fired before any is awaited, so the four requests run concurrently.
class ProfileController extends StateNotifier<ProfileState> {
  final WanderpostApi api;

  ProfileController(this.api) : super(const ProfileState.loading());

  Future<void> load() async {
    state = const ProfileState.loading();
    try {
      final meFuture = api.me();
      final mapFuture = api.meMap();
      final coverageFuture = api.meCoverage();
      final leaderboardFuture = api.leaderboardCoverage(window: 'weekly');
      final me = await meFuture;
      final map = await mapFuture;
      final coverage = await coverageFuture;
      final leaderboard = await leaderboardFuture;
      state = ProfileState.loaded(
        user: me.user,
        stats: me.stats,
        poiMap: map,
        coverageCount: coverage.count,
        leaderboard: leaderboard,
      );
    } on ApiException catch (e) {
      state = ProfileState.error(e.message);
    }
  }
}
