import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import 'profile_state.dart';

/// SPEC §14/§16 — loads `/me`, `/me/map`, `/me/coverage`, the weekly coverage
/// leaderboard, and `/me/badges`. Each call is fired before any is awaited, so all five
/// requests run concurrently.
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
      final badgesFuture = api.meBadges();
      final me = await meFuture;
      final map = await mapFuture;
      final coverage = await coverageFuture;
      final leaderboard = await leaderboardFuture;
      final badges = await badgesFuture;
      state = ProfileState.loaded(
        user: me.user,
        stats: me.stats,
        poiMap: map,
        coverageCount: coverage.count,
        leaderboard: leaderboard,
        badges: badges,
      );
    } on ApiException catch (e) {
      state = ProfileState.error(e.message);
    }
  }

  /// SPEC §21 `PATCH /me/display-name`. Rethrows `ApiException` (e.g. a profanity-flagged
  /// name) so the caller can show it inline rather than replacing the whole screen with
  /// an error state over one rejected edit.
  Future<void> setDisplayName(String? displayName) async {
    final newDisplayName = await api.setDisplayName(displayName);
    state.whenOrNull(
      loaded: (user, stats, poiMap, coverageCount, leaderboard, badges) {
        state = ProfileState.loaded(
          user: user.copyWith(displayName: newDisplayName),
          stats: stats,
          poiMap: poiMap,
          coverageCount: coverageCount,
          leaderboard: leaderboard,
          badges: badges,
        );
      },
    );
  }
}
