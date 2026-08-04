import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_postcard.freezed.dart';

/// SPEC §20 `GET /me/postcards`' items — the caller's own sent postcards, newest first,
/// including already-revoked ones (`revokedAt` non-null) so the screen reads as a real
/// history rather than a shrinking active set.
@freezed
class MyPostcard with _$MyPostcard {
  const factory MyPostcard({
    required String id,
    required String token,
    required String url,
    required String poiTitle,
    required String createdAt,
    String? revokedAt,
  }) = _MyPostcard;

  factory MyPostcard.fromMap(Map<String, dynamic> json) => MyPostcard(
        id: json['id'] as String,
        token: json['token'] as String,
        url: json['url'] as String,
        poiTitle: json['poiTitle'] as String,
        createdAt: json['createdAt'] as String,
        revokedAt: json['revokedAt'] as String?,
      );
}
