// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_pin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PoiPin {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  LatLng get location => throw _privateConstructorUsedError;
  int get checkinCount => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;

  /// Create a copy of PoiPin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiPinCopyWith<PoiPin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiPinCopyWith<$Res> {
  factory $PoiPinCopyWith(PoiPin value, $Res Function(PoiPin) then) =
      _$PoiPinCopyWithImpl<$Res, PoiPin>;
  @useResult
  $Res call({
    String id,
    String title,
    String category,
    LatLng location,
    int checkinCount,
    String? thumbnailUrl,
  });

  $LatLngCopyWith<$Res> get location;
}

/// @nodoc
class _$PoiPinCopyWithImpl<$Res, $Val extends PoiPin>
    implements $PoiPinCopyWith<$Res> {
  _$PoiPinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiPin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? location = null,
    Object? checkinCount = null,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as LatLng,
            checkinCount: null == checkinCount
                ? _value.checkinCount
                : checkinCount // ignore: cast_nullable_to_non_nullable
                      as int,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of PoiPin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LatLngCopyWith<$Res> get location {
    return $LatLngCopyWith<$Res>(_value.location, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PoiPinImplCopyWith<$Res> implements $PoiPinCopyWith<$Res> {
  factory _$$PoiPinImplCopyWith(
    _$PoiPinImpl value,
    $Res Function(_$PoiPinImpl) then,
  ) = __$$PoiPinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String category,
    LatLng location,
    int checkinCount,
    String? thumbnailUrl,
  });

  @override
  $LatLngCopyWith<$Res> get location;
}

/// @nodoc
class __$$PoiPinImplCopyWithImpl<$Res>
    extends _$PoiPinCopyWithImpl<$Res, _$PoiPinImpl>
    implements _$$PoiPinImplCopyWith<$Res> {
  __$$PoiPinImplCopyWithImpl(
    _$PoiPinImpl _value,
    $Res Function(_$PoiPinImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoiPin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? location = null,
    Object? checkinCount = null,
    Object? thumbnailUrl = freezed,
  }) {
    return _then(
      _$PoiPinImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as LatLng,
        checkinCount: null == checkinCount
            ? _value.checkinCount
            : checkinCount // ignore: cast_nullable_to_non_nullable
                  as int,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PoiPinImpl implements _PoiPin {
  const _$PoiPinImpl({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.checkinCount,
    this.thumbnailUrl,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String category;
  @override
  final LatLng location;
  @override
  final int checkinCount;
  @override
  final String? thumbnailUrl;

  @override
  String toString() {
    return 'PoiPin(id: $id, title: $title, category: $category, location: $location, checkinCount: $checkinCount, thumbnailUrl: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiPinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.checkinCount, checkinCount) ||
                other.checkinCount == checkinCount) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    category,
    location,
    checkinCount,
    thumbnailUrl,
  );

  /// Create a copy of PoiPin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiPinImplCopyWith<_$PoiPinImpl> get copyWith =>
      __$$PoiPinImplCopyWithImpl<_$PoiPinImpl>(this, _$identity);
}

abstract class _PoiPin implements PoiPin {
  const factory _PoiPin({
    required final String id,
    required final String title,
    required final String category,
    required final LatLng location,
    required final int checkinCount,
    final String? thumbnailUrl,
  }) = _$PoiPinImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get category;
  @override
  LatLng get location;
  @override
  int get checkinCount;
  @override
  String? get thumbnailUrl;

  /// Create a copy of PoiPin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiPinImplCopyWith<_$PoiPinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
