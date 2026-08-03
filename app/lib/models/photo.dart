import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';

/// SPEC §7: `Photo = {id, urlCard, urlThumb, voteScore, myVote, uploader: {handle},
/// status}`. `myVote` (M2) is the one caller-specific field — `false` for an
/// unauthenticated caller or one who hasn't voted.
@freezed
class Photo with _$Photo {
  const factory Photo({
    required String id,
    required String urlCard,
    required String urlThumb,
    required int voteScore,
    required bool myVote,
    required String uploaderHandle,
    required String status,
  }) = _Photo;

  factory Photo.fromMap(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        urlCard: json['urlCard'] as String,
        urlThumb: json['urlThumb'] as String,
        voteScore: json['voteScore'] as int,
        myVote: json['myVote'] as bool,
        uploaderHandle: (json['uploader'] as Map<String, dynamic>)['handle'] as String,
        status: json['status'] as String,
      );
}
