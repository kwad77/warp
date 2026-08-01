// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queued_checkin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QueuedCheckin {
  String get id => throw _privateConstructorUsedError;
  String get poiId => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  List<GpsFix> get fixes => throw _privateConstructorUsedError;
  DateTime get attemptedAt => throw _privateConstructorUsedError;
  String? get photoPath => throw _privateConstructorUsedError;
  DateTime? get photoCapturedAt => throw _privateConstructorUsedError;

  /// Create a copy of QueuedCheckin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QueuedCheckinCopyWith<QueuedCheckin> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueuedCheckinCopyWith<$Res> {
  factory $QueuedCheckinCopyWith(
    QueuedCheckin value,
    $Res Function(QueuedCheckin) then,
  ) = _$QueuedCheckinCopyWithImpl<$Res, QueuedCheckin>;
  @useResult
  $Res call({
    String id,
    String poiId,
    String mode,
    List<GpsFix> fixes,
    DateTime attemptedAt,
    String? photoPath,
    DateTime? photoCapturedAt,
  });
}

/// @nodoc
class _$QueuedCheckinCopyWithImpl<$Res, $Val extends QueuedCheckin>
    implements $QueuedCheckinCopyWith<$Res> {
  _$QueuedCheckinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QueuedCheckin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? mode = null,
    Object? fixes = null,
    Object? attemptedAt = null,
    Object? photoPath = freezed,
    Object? photoCapturedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            poiId: null == poiId
                ? _value.poiId
                : poiId // ignore: cast_nullable_to_non_nullable
                      as String,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String,
            fixes: null == fixes
                ? _value.fixes
                : fixes // ignore: cast_nullable_to_non_nullable
                      as List<GpsFix>,
            attemptedAt: null == attemptedAt
                ? _value.attemptedAt
                : attemptedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            photoPath: freezed == photoPath
                ? _value.photoPath
                : photoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoCapturedAt: freezed == photoCapturedAt
                ? _value.photoCapturedAt
                : photoCapturedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QueuedCheckinImplCopyWith<$Res>
    implements $QueuedCheckinCopyWith<$Res> {
  factory _$$QueuedCheckinImplCopyWith(
    _$QueuedCheckinImpl value,
    $Res Function(_$QueuedCheckinImpl) then,
  ) = __$$QueuedCheckinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String poiId,
    String mode,
    List<GpsFix> fixes,
    DateTime attemptedAt,
    String? photoPath,
    DateTime? photoCapturedAt,
  });
}

/// @nodoc
class __$$QueuedCheckinImplCopyWithImpl<$Res>
    extends _$QueuedCheckinCopyWithImpl<$Res, _$QueuedCheckinImpl>
    implements _$$QueuedCheckinImplCopyWith<$Res> {
  __$$QueuedCheckinImplCopyWithImpl(
    _$QueuedCheckinImpl _value,
    $Res Function(_$QueuedCheckinImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QueuedCheckin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? mode = null,
    Object? fixes = null,
    Object? attemptedAt = null,
    Object? photoPath = freezed,
    Object? photoCapturedAt = freezed,
  }) {
    return _then(
      _$QueuedCheckinImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        poiId: null == poiId
            ? _value.poiId
            : poiId // ignore: cast_nullable_to_non_nullable
                  as String,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
        fixes: null == fixes
            ? _value._fixes
            : fixes // ignore: cast_nullable_to_non_nullable
                  as List<GpsFix>,
        attemptedAt: null == attemptedAt
            ? _value.attemptedAt
            : attemptedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        photoPath: freezed == photoPath
            ? _value.photoPath
            : photoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoCapturedAt: freezed == photoCapturedAt
            ? _value.photoCapturedAt
            : photoCapturedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$QueuedCheckinImpl extends _QueuedCheckin {
  const _$QueuedCheckinImpl({
    required this.id,
    required this.poiId,
    required this.mode,
    required final List<GpsFix> fixes,
    required this.attemptedAt,
    this.photoPath,
    this.photoCapturedAt,
  }) : _fixes = fixes,
       super._();

  @override
  final String id;
  @override
  final String poiId;
  @override
  final String mode;
  final List<GpsFix> _fixes;
  @override
  List<GpsFix> get fixes {
    if (_fixes is EqualUnmodifiableListView) return _fixes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fixes);
  }

  @override
  final DateTime attemptedAt;
  @override
  final String? photoPath;
  @override
  final DateTime? photoCapturedAt;

  @override
  String toString() {
    return 'QueuedCheckin(id: $id, poiId: $poiId, mode: $mode, fixes: $fixes, attemptedAt: $attemptedAt, photoPath: $photoPath, photoCapturedAt: $photoCapturedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueuedCheckinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poiId, poiId) || other.poiId == poiId) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other._fixes, _fixes) &&
            (identical(other.attemptedAt, attemptedAt) ||
                other.attemptedAt == attemptedAt) &&
            (identical(other.photoPath, photoPath) ||
                other.photoPath == photoPath) &&
            (identical(other.photoCapturedAt, photoCapturedAt) ||
                other.photoCapturedAt == photoCapturedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    poiId,
    mode,
    const DeepCollectionEquality().hash(_fixes),
    attemptedAt,
    photoPath,
    photoCapturedAt,
  );

  /// Create a copy of QueuedCheckin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QueuedCheckinImplCopyWith<_$QueuedCheckinImpl> get copyWith =>
      __$$QueuedCheckinImplCopyWithImpl<_$QueuedCheckinImpl>(this, _$identity);
}

abstract class _QueuedCheckin extends QueuedCheckin {
  const factory _QueuedCheckin({
    required final String id,
    required final String poiId,
    required final String mode,
    required final List<GpsFix> fixes,
    required final DateTime attemptedAt,
    final String? photoPath,
    final DateTime? photoCapturedAt,
  }) = _$QueuedCheckinImpl;
  const _QueuedCheckin._() : super._();

  @override
  String get id;
  @override
  String get poiId;
  @override
  String get mode;
  @override
  List<GpsFix> get fixes;
  @override
  DateTime get attemptedAt;
  @override
  String? get photoPath;
  @override
  DateTime? get photoCapturedAt;

  /// Create a copy of QueuedCheckin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QueuedCheckinImplCopyWith<_$QueuedCheckinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
