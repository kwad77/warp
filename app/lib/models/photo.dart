import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';

/// SPEC §7: `Photo = {id, urlCard, urlThumb, voteScore, uploader: {handle}, status}`.
@freezed
class Photo with _$Photo {
  const factory Photo({
    required String id,
    required String urlCard,
    required String urlThumb,
    required int voteScore,
    required String uploaderHandle,
    required String status,
  }) = _Photo;

  factory Photo.fromMap(Map<String, dynamic> json) => Photo(
        id: json['id'] as String,
        urlCard: json['urlCard'] as String,
        urlThumb: json['urlThumb'] as String,
        voteScore: json['voteScore'] as int,
        uploaderHandle: (json['uploader'] as Map<String, dynamic>)['handle'] as String,
        status: json['status'] as String,
      );
}
