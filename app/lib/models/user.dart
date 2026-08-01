import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// SPEC §7: `User = {id, handle, createdAt}`.
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String handle,
    required String createdAt,
  }) = _User;

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        handle: json['handle'] as String,
        createdAt: json['createdAt'] as String,
      );
}
