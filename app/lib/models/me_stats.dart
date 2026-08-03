import 'package:freezed_annotation/freezed_annotation.dart';

part 'me_stats.freezed.dart';

/// SPEC §7 `GET /me`'s `stats`.
@freezed
class MeStats with _$MeStats {
  const factory MeStats({
    required int checkins,
    required int cellsCovered,
    required int poisCreated,
    required int creatorScore,
  }) = _MeStats;

  factory MeStats.fromMap(Map<String, dynamic> json) => MeStats(
        checkins: json['checkins'] as int,
        cellsCovered: json['cellsCovered'] as int,
        poisCreated: json['poisCreated'] as int,
        creatorScore: json['creatorScore'] as int,
      );
}
