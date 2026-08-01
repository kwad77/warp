// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Poi {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  LatLng get location => throw _privateConstructorUsedError;
  int get checkinCount => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get creatorId => throw _privateConstructorUsedError;
  String get creatorHandle => throw _privateConstructorUsedError;
  int get checkinRadiusM => throw _privateConstructorUsedError;
  List<Photo> get gallery => throw _privateConstructorUsedError;

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiCopyWith<Poi> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiCopyWith<$Res> {
  factory $PoiCopyWith(Poi value, $Res Function(Poi) then) =
      _$PoiCopyWithImpl<$Res, Poi>;
  @useResult
  $Res call({
    String id,
    String title,
    String category,
    LatLng location,
    int checkinCount,
    String? description,
    String creatorId,
    String creatorHandle,
    int checkinRadiusM,
    List<Photo> gallery,
  });

  $LatLngCopyWith<$Res> get location;
}

/// @nodoc
class _$PoiCopyWithImpl<$Res, $Val extends Poi> implements $PoiCopyWith<$Res> {
  _$PoiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? location = null,
    Object? checkinCount = null,
    Object? description = freezed,
    Object? creatorId = null,
    Object? creatorHandle = null,
    Object? checkinRadiusM = null,
    Object? gallery = null,
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
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            creatorId: null == creatorId
                ? _value.creatorId
                : creatorId // ignore: cast_nullable_to_non_nullable
                      as String,
            creatorHandle: null == creatorHandle
                ? _value.creatorHandle
                : creatorHandle // ignore: cast_nullable_to_non_nullable
                      as String,
            checkinRadiusM: null == checkinRadiusM
                ? _value.checkinRadiusM
                : checkinRadiusM // ignore: cast_nullable_to_non_nullable
                      as int,
            gallery: null == gallery
                ? _value.gallery
                : gallery // ignore: cast_nullable_to_non_nullable
                      as List<Photo>,
          )
          as $Val,
    );
  }

  /// Create a copy of Poi
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
abstract class _$$PoiImplCopyWith<$Res> implements $PoiCopyWith<$Res> {
  factory _$$PoiImplCopyWith(_$PoiImpl value, $Res Function(_$PoiImpl) then) =
      __$$PoiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String category,
    LatLng location,
    int checkinCount,
    String? description,
    String creatorId,
    String creatorHandle,
    int checkinRadiusM,
    List<Photo> gallery,
  });

  @override
  $LatLngCopyWith<$Res> get location;
}

/// @nodoc
class __$$PoiImplCopyWithImpl<$Res> extends _$PoiCopyWithImpl<$Res, _$PoiImpl>
    implements _$$PoiImplCopyWith<$Res> {
  __$$PoiImplCopyWithImpl(_$PoiImpl _value, $Res Function(_$PoiImpl) _then)
    : super(_value, _then);

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? location = null,
    Object? checkinCount = null,
    Object? description = freezed,
    Object? creatorId = null,
    Object? creatorHandle = null,
    Object? checkinRadiusM = null,
    Object? gallery = null,
  }) {
    return _then(
      _$PoiImpl(
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
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        creatorId: null == creatorId
            ? _value.creatorId
            : creatorId // ignore: cast_nullable_to_non_nullable
                  as String,
        creatorHandle: null == creatorHandle
            ? _value.creatorHandle
            : creatorHandle // ignore: cast_nullable_to_non_nullable
                  as String,
        checkinRadiusM: null == checkinRadiusM
            ? _value.checkinRadiusM
            : checkinRadiusM // ignore: cast_nullable_to_non_nullable
                  as int,
        gallery: null == gallery
            ? _value._gallery
            : gallery // ignore: cast_nullable_to_non_nullable
                  as List<Photo>,
      ),
    );
  }
}

/// @nodoc

class _$PoiImpl implements _Poi {
  const _$PoiImpl({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.checkinCount,
    this.description,
    required this.creatorId,
    required this.creatorHandle,
    required this.checkinRadiusM,
    required final List<Photo> gallery,
  }) : _gallery = gallery;

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
  final String? description;
  @override
  final String creatorId;
  @override
  final String creatorHandle;
  @override
  final int checkinRadiusM;
  final List<Photo> _gallery;
  @override
  List<Photo> get gallery {
    if (_gallery is EqualUnmodifiableListView) return _gallery;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gallery);
  }

  @override
  String toString() {
    return 'Poi(id: $id, title: $title, category: $category, location: $location, checkinCount: $checkinCount, description: $description, creatorId: $creatorId, creatorHandle: $creatorHandle, checkinRadiusM: $checkinRadiusM, gallery: $gallery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.checkinCount, checkinCount) ||
                other.checkinCount == checkinCount) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.creatorHandle, creatorHandle) ||
                other.creatorHandle == creatorHandle) &&
            (identical(other.checkinRadiusM, checkinRadiusM) ||
                other.checkinRadiusM == checkinRadiusM) &&
            const DeepCollectionEquality().equals(other._gallery, _gallery));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    category,
    location,
    checkinCount,
    description,
    creatorId,
    creatorHandle,
    checkinRadiusM,
    const DeepCollectionEquality().hash(_gallery),
  );

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiImplCopyWith<_$PoiImpl> get copyWith =>
      __$$PoiImplCopyWithImpl<_$PoiImpl>(this, _$identity);
}

abstract class _Poi implements Poi {
  const factory _Poi({
    required final String id,
    required final String title,
    required final String category,
    required final LatLng location,
    required final int checkinCount,
    final String? description,
    required final String creatorId,
    required final String creatorHandle,
    required final int checkinRadiusM,
    required final List<Photo> gallery,
  }) = _$PoiImpl;

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
  String? get description;
  @override
  String get creatorId;
  @override
  String get creatorHandle;
  @override
  int get checkinRadiusM;
  @override
  List<Photo> get gallery;

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiImplCopyWith<_$PoiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
