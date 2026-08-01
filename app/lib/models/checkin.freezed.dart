// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Checkin {
  String get id => throw _privateConstructorUsedError;
  String get poiId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;
  String get evidence => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get verifiedAt => throw _privateConstructorUsedError;

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckinCopyWith<Checkin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckinCopyWith<$Res> {
  factory $CheckinCopyWith(Checkin value, $Res Function(Checkin) then) =
      _$CheckinCopyWithImpl<$Res, Checkin>;
  @useResult
  $Res call({
    String id,
    String poiId,
    String status,
    String mode,
    String evidence,
    String createdAt,
    String? verifiedAt,
  });
}

/// @nodoc
class _$CheckinCopyWithImpl<$Res, $Val extends Checkin>
    implements $CheckinCopyWith<$Res> {
  _$CheckinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? status = null,
    Object? mode = null,
    Object? evidence = null,
    Object? createdAt = null,
    Object? verifiedAt = freezed,
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String,
            evidence: null == evidence
                ? _value.evidence
                : evidence // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            verifiedAt: freezed == verifiedAt
                ? _value.verifiedAt
                : verifiedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CheckinImplCopyWith<$Res> implements $CheckinCopyWith<$Res> {
  factory _$$CheckinImplCopyWith(
    _$CheckinImpl value,
    $Res Function(_$CheckinImpl) then,
  ) = __$$CheckinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String poiId,
    String status,
    String mode,
    String evidence,
    String createdAt,
    String? verifiedAt,
  });
}

/// @nodoc
class __$$CheckinImplCopyWithImpl<$Res>
    extends _$CheckinCopyWithImpl<$Res, _$CheckinImpl>
    implements _$$CheckinImplCopyWith<$Res> {
  __$$CheckinImplCopyWithImpl(
    _$CheckinImpl _value,
    $Res Function(_$CheckinImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? status = null,
    Object? mode = null,
    Object? evidence = null,
    Object? createdAt = null,
    Object? verifiedAt = freezed,
  }) {
    return _then(
      _$CheckinImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        poiId: null == poiId
            ? _value.poiId
            : poiId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
        evidence: null == evidence
            ? _value.evidence
            : evidence // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        verifiedAt: freezed == verifiedAt
            ? _value.verifiedAt
            : verifiedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$CheckinImpl implements _Checkin {
  const _$CheckinImpl({
    required this.id,
    required this.poiId,
    required this.status,
    required this.mode,
    required this.evidence,
    required this.createdAt,
    this.verifiedAt,
  });

  @override
  final String id;
  @override
  final String poiId;
  @override
  final String status;
  @override
  final String mode;
  @override
  final String evidence;
  @override
  final String createdAt;
  @override
  final String? verifiedAt;

  @override
  String toString() {
    return 'Checkin(id: $id, poiId: $poiId, status: $status, mode: $mode, evidence: $evidence, createdAt: $createdAt, verifiedAt: $verifiedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poiId, poiId) || other.poiId == poiId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.evidence, evidence) ||
                other.evidence == evidence) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    poiId,
    status,
    mode,
    evidence,
    createdAt,
    verifiedAt,
  );

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckinImplCopyWith<_$CheckinImpl> get copyWith =>
      __$$CheckinImplCopyWithImpl<_$CheckinImpl>(this, _$identity);
}

abstract class _Checkin implements Checkin {
  const factory _Checkin({
    required final String id,
    required final String poiId,
    required final String status,
    required final String mode,
    required final String evidence,
    required final String createdAt,
    final String? verifiedAt,
  }) = _$CheckinImpl;

  @override
  String get id;
  @override
  String get poiId;
  @override
  String get status;
  @override
  String get mode;
  @override
  String get evidence;
  @override
  String get createdAt;
  @override
  String? get verifiedAt;

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckinImplCopyWith<_$CheckinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
