import 'package:freezed_annotation/freezed_annotation.dart';

import 'leaderboard_entry.dart';

part 'leaderboard_result.freezed.dart';

/// SPEC §7 `GET /leaderboards/coverage`. `me` is present only with a valid bearer token.
@freezed
class LeaderboardResult with _$LeaderboardResult {
  const factory LeaderboardResult({
    required List<LeaderboardEntry> entries,
    MeStanding? me,
  }) = _LeaderboardResult;

  factory LeaderboardResult.fromMap(Map<String, dynamic> json) => LeaderboardResult(
        entries: (json['entries'] as List<dynamic>)
            .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
        me: json['me'] != null ? MeStanding.fromMap(json['me'] as Map<String, dynamic>) : null,
      );
}
