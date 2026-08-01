// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queued_poi_creation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QueuedPoiCreation {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  LatLng get location => throw _privateConstructorUsedError;
  GpsFix get gpsFix => throw _privateConstructorUsedError;
  String? get photoPath => throw _privateConstructorUsedError;

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QueuedPoiCreationCopyWith<QueuedPoiCreation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueuedPoiCreationCopyWith<$Res> {
  factory $QueuedPoiCreationCopyWith(
    QueuedPoiCreation value,
    $Res Function(QueuedPoiCreation) then,
  ) = _$QueuedPoiCreationCopyWithImpl<$Res, QueuedPoiCreation>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    String category,
    LatLng location,
    GpsFix gpsFix,
    String? photoPath,
  });

  $LatLngCopyWith<$Res> get location;
  $GpsFixCopyWith<$Res> get gpsFix;
}

/// @nodoc
class _$QueuedPoiCreationCopyWithImpl<$Res, $Val extends QueuedPoiCreation>
    implements $QueuedPoiCreationCopyWith<$Res> {
  _$QueuedPoiCreationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? category = null,
    Object? location = null,
    Object? gpsFix = null,
    Object? photoPath = freezed,
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
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as LatLng,
            gpsFix: null == gpsFix
                ? _value.gpsFix
                : gpsFix // ignore: cast_nullable_to_non_nullable
                      as GpsFix,
            photoPath: freezed == photoPath
                ? _value.photoPath
                : photoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LatLngCopyWith<$Res> get location {
    return $LatLngCopyWith<$Res>(_value.location, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GpsFixCopyWith<$Res> get gpsFix {
    return $GpsFixCopyWith<$Res>(_value.gpsFix, (value) {
      return _then(_value.copyWith(gpsFix: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$QueuedPoiCreationImplCopyWith<$Res>
    implements $QueuedPoiCreationCopyWith<$Res> {
  factory _$$QueuedPoiCreationImplCopyWith(
    _$QueuedPoiCreationImpl value,
    $Res Function(_$QueuedPoiCreationImpl) then,
  ) = __$$QueuedPoiCreationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    String category,
    LatLng location,
    GpsFix gpsFix,
    String? photoPath,
  });

  @override
  $LatLngCopyWith<$Res> get location;
  @override
  $GpsFixCopyWith<$Res> get gpsFix;
}

/// @nodoc
class __$$QueuedPoiCreationImplCopyWithImpl<$Res>
    extends _$QueuedPoiCreationCopyWithImpl<$Res, _$QueuedPoiCreationImpl>
    implements _$$QueuedPoiCreationImplCopyWith<$Res> {
  __$$QueuedPoiCreationImplCopyWithImpl(
    _$QueuedPoiCreationImpl _value,
    $Res Function(_$QueuedPoiCreationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? category = null,
    Object? location = null,
    Object? gpsFix = null,
    Object? photoPath = freezed,
  }) {
    return _then(
      _$QueuedPoiCreationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as LatLng,
        gpsFix: null == gpsFix
            ? _value.gpsFix
            : gpsFix // ignore: cast_nullable_to_non_nullable
                  as GpsFix,
        photoPath: freezed == photoPath
            ? _value.photoPath
            : photoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$QueuedPoiCreationImpl extends _QueuedPoiCreation {
  const _$QueuedPoiCreationImpl({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.location,
    required this.gpsFix,
    this.photoPath,
  }) : super._();

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String category;
  @override
  final LatLng location;
  @override
  final GpsFix gpsFix;
  @override
  final String? photoPath;

  @override
  String toString() {
    return 'QueuedPoiCreation(id: $id, title: $title, description: $description, category: $category, location: $location, gpsFix: $gpsFix, photoPath: $photoPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueuedPoiCreationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.gpsFix, gpsFix) || other.gpsFix == gpsFix) &&
            (identical(other.photoPath, photoPath) ||
                other.photoPath == photoPath));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    category,
    location,
    gpsFix,
    photoPath,
  );

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QueuedPoiCreationImplCopyWith<_$QueuedPoiCreationImpl> get copyWith =>
      __$$QueuedPoiCreationImplCopyWithImpl<_$QueuedPoiCreationImpl>(
        this,
        _$identity,
      );
}

abstract class _QueuedPoiCreation extends QueuedPoiCreation {
  const factory _QueuedPoiCreation({
    required final String id,
    required final String title,
    final String? description,
    required final String category,
    required final LatLng location,
    required final GpsFix gpsFix,
    final String? photoPath,
  }) = _$QueuedPoiCreationImpl;
  const _QueuedPoiCreation._() : super._();

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get category;
  @override
  LatLng get location;
  @override
  GpsFix get gpsFix;
  @override
  String? get photoPath;

  /// Create a copy of QueuedPoiCreation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QueuedPoiCreationImplCopyWith<_$QueuedPoiCreationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
