import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_badge.freezed.dart';

/// SPEC §7/§16 `GET /me/badges`'s `badges[]`. Named `UserBadge`, not `Badge` — the latter
/// collides with `package:flutter/material.dart`'s notification-dot widget.
@freezed
class UserBadge with _$UserBadge {
  const factory UserBadge({
    required String badgeKey,
    required String awardedAt,
  }) = _UserBadge;

  factory UserBadge.fromMap(Map<String, dynamic> json) => UserBadge(
        badgeKey: json['badgeKey'] as String,
        awardedAt: json['awardedAt'] as String,
      );
}
