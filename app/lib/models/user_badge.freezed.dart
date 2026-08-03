// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_badge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserBadge {
  String get badgeKey => throw _privateConstructorUsedError;
  String get awardedAt => throw _privateConstructorUsedError;

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserBadgeCopyWith<UserBadge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserBadgeCopyWith<$Res> {
  factory $UserBadgeCopyWith(UserBadge value, $Res Function(UserBadge) then) =
      _$UserBadgeCopyWithImpl<$Res, UserBadge>;
  @useResult
  $Res call({String badgeKey, String awardedAt});
}

/// @nodoc
class _$UserBadgeCopyWithImpl<$Res, $Val extends UserBadge>
    implements $UserBadgeCopyWith<$Res> {
  _$UserBadgeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? badgeKey = null, Object? awardedAt = null}) {
    return _then(
      _value.copyWith(
            badgeKey: null == badgeKey
                ? _value.badgeKey
                : badgeKey // ignore: cast_nullable_to_non_nullable
                      as String,
            awardedAt: null == awardedAt
                ? _value.awardedAt
                : awardedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserBadgeImplCopyWith<$Res>
    implements $UserBadgeCopyWith<$Res> {
  factory _$$UserBadgeImplCopyWith(
    _$UserBadgeImpl value,
    $Res Function(_$UserBadgeImpl) then,
  ) = __$$UserBadgeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String badgeKey, String awardedAt});
}

/// @nodoc
class __$$UserBadgeImplCopyWithImpl<$Res>
    extends _$UserBadgeCopyWithImpl<$Res, _$UserBadgeImpl>
    implements _$$UserBadgeImplCopyWith<$Res> {
  __$$UserBadgeImplCopyWithImpl(
    _$UserBadgeImpl _value,
    $Res Function(_$UserBadgeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? badgeKey = null, Object? awardedAt = null}) {
    return _then(
      _$UserBadgeImpl(
        badgeKey: null == badgeKey
            ? _value.badgeKey
            : badgeKey // ignore: cast_nullable_to_non_nullable
                  as String,
        awardedAt: null == awardedAt
            ? _value.awardedAt
            : awardedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UserBadgeImpl implements _UserBadge {
  const _$UserBadgeImpl({required this.badgeKey, required this.awardedAt});

  @override
  final String badgeKey;
  @override
  final String awardedAt;

  @override
  String toString() {
    return 'UserBadge(badgeKey: $badgeKey, awardedAt: $awardedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserBadgeImpl &&
            (identical(other.badgeKey, badgeKey) ||
                other.badgeKey == badgeKey) &&
            (identical(other.awardedAt, awardedAt) ||
                other.awardedAt == awardedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, badgeKey, awardedAt);

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserBadgeImplCopyWith<_$UserBadgeImpl> get copyWith =>
      __$$UserBadgeImplCopyWithImpl<_$UserBadgeImpl>(this, _$identity);
}

abstract class _UserBadge implements UserBadge {
  const factory _UserBadge({
    required final String badgeKey,
    required final String awardedAt,
  }) = _$UserBadgeImpl;

  @override
  String get badgeKey;
  @override
  String get awardedAt;

  /// Create a copy of UserBadge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserBadgeImplCopyWith<_$UserBadgeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
