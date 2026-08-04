import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';

/// SPEC §7: `Photo = {id, urlCard, urlThumb, voteScore, myVote, uploader: {handle},
/// contributorName, status}`. `myVote` (M2) is the one caller-specific field — `false`
/// for an unauthenticated caller or one who hasn't voted. `contributorName` (§21, M2) is
/// the uploader's opt-in display name, `null` if they haven't set one — never falls back
/// to `uploaderHandle`; an un-named contributor is uncredited, not credited by their
/// auto-generated handle.
@freezed
class Photo with _$Photo {
  const factory Photo({
    required String id,
    required String urlCard,
    required String urlThumb,
    required int voteScore,
    required bool myVote,
    required String uploaderHandle,
    String? contributorName,
    required String status,
  }) = _Photo;

  factory Photo.fromMap(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        urlCard: json['urlCard'] as String,
        urlThumb: json['urlThumb'] as String,
        voteScore: json['voteScore'] as int,
        myVote: json['myVote'] as bool,
        uploaderHandle: (json['uploader'] as Map<String, dynamic>)['handle'] as String,
        contributorName: json['contributorName'] as String?,
        status: json['status'] as String,
      );
}
