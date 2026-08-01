// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gps_fix.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GpsFix {
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  double get accuracyM => throw _privateConstructorUsedError;
  DateTime get capturedAt => throw _privateConstructorUsedError;

  /// Create a copy of GpsFix
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GpsFixCopyWith<GpsFix> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GpsFixCopyWith<$Res> {
  factory $GpsFixCopyWith(GpsFix value, $Res Function(GpsFix) then) =
      _$GpsFixCopyWithImpl<$Res, GpsFix>;
  @useResult
  $Res call({double lat, double lng, double accuracyM, DateTime capturedAt});
}

/// @nodoc
class _$GpsFixCopyWithImpl<$Res, $Val extends GpsFix>
    implements $GpsFixCopyWith<$Res> {
  _$GpsFixCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GpsFix
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? accuracyM = null,
    Object? capturedAt = null,
  }) {
    return _then(
      _value.copyWith(
            lat: null == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double,
            lng: null == lng
                ? _value.lng
                : lng // ignore: cast_nullable_to_non_nullable
                      as double,
            accuracyM: null == accuracyM
                ? _value.accuracyM
                : accuracyM // ignore: cast_nullable_to_non_nullable
                      as double,
            capturedAt: null == capturedAt
                ? _value.capturedAt
                : capturedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GpsFixImplCopyWith<$Res> implements $GpsFixCopyWith<$Res> {
  factory _$$GpsFixImplCopyWith(
    _$GpsFixImpl value,
    $Res Function(_$GpsFixImpl) then,
  ) = __$$GpsFixImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double lat, double lng, double accuracyM, DateTime capturedAt});
}

/// @nodoc
class __$$GpsFixImplCopyWithImpl<$Res>
    extends _$GpsFixCopyWithImpl<$Res, _$GpsFixImpl>
    implements _$$GpsFixImplCopyWith<$Res> {
  __$$GpsFixImplCopyWithImpl(
    _$GpsFixImpl _value,
    $Res Function(_$GpsFixImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GpsFix
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? accuracyM = null,
    Object? capturedAt = null,
  }) {
    return _then(
      _$GpsFixImpl(
        lat: null == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double,
        lng: null == lng
            ? _value.lng
            : lng // ignore: cast_nullable_to_non_nullable
                  as double,
        accuracyM: null == accuracyM
            ? _value.accuracyM
            : accuracyM // ignore: cast_nullable_to_non_nullable
                  as double,
        capturedAt: null == capturedAt
            ? _value.capturedAt
            : capturedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$GpsFixImpl extends _GpsFix {
  const _$GpsFixImpl({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.capturedAt,
  }) : super._();

  @override
  final double lat;
  @override
  final double lng;
  @override
  final double accuracyM;
  @override
  final DateTime capturedAt;

  @override
  String toString() {
    return 'GpsFix(lat: $lat, lng: $lng, accuracyM: $accuracyM, capturedAt: $capturedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GpsFixImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.accuracyM, accuracyM) ||
                other.accuracyM == accuracyM) &&
            (identical(other.capturedAt, capturedAt) ||
                other.capturedAt == capturedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, lat, lng, accuracyM, capturedAt);

  /// Create a copy of GpsFix
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GpsFixImplCopyWith<_$GpsFixImpl> get copyWith =>
      __$$GpsFixImplCopyWithImpl<_$GpsFixImpl>(this, _$identity);
}

abstract class _GpsFix extends GpsFix {
  const factory _GpsFix({
    required final double lat,
    required final double lng,
    required final double accuracyM,
    required final DateTime capturedAt,
  }) = _$GpsFixImpl;
  const _GpsFix._() : super._();

  @override
  double get lat;
  @override
  double get lng;
  @override
  double get accuracyM;
  @override
  DateTime get capturedAt;

  /// Create a copy of GpsFix
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GpsFixImplCopyWith<_$GpsFixImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
