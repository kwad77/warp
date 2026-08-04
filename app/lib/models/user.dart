import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// SPEC §7: `User = {id, handle, displayName, createdAt}`. `displayName` (§21, M2) is
/// the caller's own opt-in choice, distinct from the immutable, auto-generated `handle`.
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String handle,
    String? displayName,
    required String createdAt,
  }) = _User;

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        handle: json['handle'] as String,
        displayName: json['displayName'] as String?,
        createdAt: json['createdAt'] as String,
      );
}
