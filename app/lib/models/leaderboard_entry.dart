import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';

/// SPEC §7 `GET /leaderboards/coverage`'s `entries[]`.
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required int rank,
    required String handle,
    required int cells,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] as int,
        handle: json['handle'] as String,
        cells: json['cells'] as int,
      );
}

/// SPEC §7 `GET /leaderboards/coverage`'s optional `me` — deliberately a separate type
/// from [LeaderboardEntry]: it never carries a `handle`.
@freezed
class MeStanding with _$MeStanding {
  const factory MeStanding({required int rank, required int cells}) = _MeStanding;

  factory MeStanding.fromMap(Map<String, dynamic> json) => MeStanding(
        rank: json['rank'] as int,
        cells: json['cells'] as int,
      );
}
