// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MeStats {
  int get checkins => throw _privateConstructorUsedError;
  int get cellsCovered => throw _privateConstructorUsedError;
  int get poisCreated => throw _privateConstructorUsedError;

  /// Create a copy of MeStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeStatsCopyWith<MeStats> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeStatsCopyWith<$Res> {
  factory $MeStatsCopyWith(MeStats value, $Res Function(MeStats) then) =
      _$MeStatsCopyWithImpl<$Res, MeStats>;
  @useResult
  $Res call({int checkins, int cellsCovered, int poisCreated});
}

/// @nodoc
class _$MeStatsCopyWithImpl<$Res, $Val extends MeStats>
    implements $MeStatsCopyWith<$Res> {
  _$MeStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkins = null,
    Object? cellsCovered = null,
    Object? poisCreated = null,
  }) {
    return _then(
      _value.copyWith(
            checkins: null == checkins
                ? _value.checkins
                : checkins // ignore: cast_nullable_to_non_nullable
                      as int,
            cellsCovered: null == cellsCovered
                ? _value.cellsCovered
                : cellsCovered // ignore: cast_nullable_to_non_nullable
                      as int,
            poisCreated: null == poisCreated
                ? _value.poisCreated
                : poisCreated // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MeStatsImplCopyWith<$Res> implements $MeStatsCopyWith<$Res> {
  factory _$$MeStatsImplCopyWith(
    _$MeStatsImpl value,
    $Res Function(_$MeStatsImpl) then,
  ) = __$$MeStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int checkins, int cellsCovered, int poisCreated});
}

/// @nodoc
class __$$MeStatsImplCopyWithImpl<$Res>
    extends _$MeStatsCopyWithImpl<$Res, _$MeStatsImpl>
    implements _$$MeStatsImplCopyWith<$Res> {
  __$$MeStatsImplCopyWithImpl(
    _$MeStatsImpl _value,
    $Res Function(_$MeStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MeStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkins = null,
    Object? cellsCovered = null,
    Object? poisCreated = null,
  }) {
    return _then(
      _$MeStatsImpl(
        checkins: null == checkins
            ? _value.checkins
            : checkins // ignore: cast_nullable_to_non_nullable
                  as int,
        cellsCovered: null == cellsCovered
            ? _value.cellsCovered
            : cellsCovered // ignore: cast_nullable_to_non_nullable
                  as int,
        poisCreated: null == poisCreated
            ? _value.poisCreated
            : poisCreated // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$MeStatsImpl implements _MeStats {
  const _$MeStatsImpl({
    required this.checkins,
    required this.cellsCovered,
    required this.poisCreated,
  });

  @override
  final int checkins;
  @override
  final int cellsCovered;
  @override
  final int poisCreated;

  @override
  String toString() {
    return 'MeStats(checkins: $checkins, cellsCovered: $cellsCovered, poisCreated: $poisCreated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeStatsImpl &&
            (identical(other.checkins, checkins) ||
                other.checkins == checkins) &&
            (identical(other.cellsCovered, cellsCovered) ||
                other.cellsCovered == cellsCovered) &&
            (identical(other.poisCreated, poisCreated) ||
                other.poisCreated == poisCreated));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, checkins, cellsCovered, poisCreated);

  /// Create a copy of MeStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeStatsImplCopyWith<_$MeStatsImpl> get copyWith =>
      __$$MeStatsImplCopyWithImpl<_$MeStatsImpl>(this, _$identity);
}

abstract class _MeStats implements MeStats {
  const factory _MeStats({
    required final int checkins,
    required final int cellsCovered,
    required final int poisCreated,
  }) = _$MeStatsImpl;

  @override
  int get checkins;
  @override
  int get cellsCovered;
  @override
  int get poisCreated;

  /// Create a copy of MeStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeStatsImplCopyWith<_$MeStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
