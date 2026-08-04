// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_postcard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MyPostcard {
  String get id => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get poiTitle => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get revokedAt => throw _privateConstructorUsedError;

  /// Create a copy of MyPostcard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPostcardCopyWith<MyPostcard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPostcardCopyWith<$Res> {
  factory $MyPostcardCopyWith(
    MyPostcard value,
    $Res Function(MyPostcard) then,
  ) = _$MyPostcardCopyWithImpl<$Res, MyPostcard>;
  @useResult
  $Res call({
    String id,
    String token,
    String url,
    String poiTitle,
    String createdAt,
    String? revokedAt,
  });
}

/// @nodoc
class _$MyPostcardCopyWithImpl<$Res, $Val extends MyPostcard>
    implements $MyPostcardCopyWith<$Res> {
  _$MyPostcardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPostcard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? token = null,
    Object? url = null,
    Object? poiTitle = null,
    Object? createdAt = null,
    Object? revokedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            poiTitle: null == poiTitle
                ? _value.poiTitle
                : poiTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            revokedAt: freezed == revokedAt
                ? _value.revokedAt
                : revokedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MyPostcardImplCopyWith<$Res>
    implements $MyPostcardCopyWith<$Res> {
  factory _$$MyPostcardImplCopyWith(
    _$MyPostcardImpl value,
    $Res Function(_$MyPostcardImpl) then,
  ) = __$$MyPostcardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String token,
    String url,
    String poiTitle,
    String createdAt,
    String? revokedAt,
  });
}

/// @nodoc
class __$$MyPostcardImplCopyWithImpl<$Res>
    extends _$MyPostcardCopyWithImpl<$Res, _$MyPostcardImpl>
    implements _$$MyPostcardImplCopyWith<$Res> {
  __$$MyPostcardImplCopyWithImpl(
    _$MyPostcardImpl _value,
    $Res Function(_$MyPostcardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPostcard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? token = null,
    Object? url = null,
    Object? poiTitle = null,
    Object? createdAt = null,
    Object? revokedAt = freezed,
  }) {
    return _then(
      _$MyPostcardImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        poiTitle: null == poiTitle
            ? _value.poiTitle
            : poiTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        revokedAt: freezed == revokedAt
            ? _value.revokedAt
            : revokedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$MyPostcardImpl implements _MyPostcard {
  const _$MyPostcardImpl({
    required this.id,
    required this.token,
    required this.url,
    required this.poiTitle,
    required this.createdAt,
    this.revokedAt,
  });

  @override
  final String id;
  @override
  final String token;
  @override
  final String url;
  @override
  final String poiTitle;
  @override
  final String createdAt;
  @override
  final String? revokedAt;

  @override
  String toString() {
    return 'MyPostcard(id: $id, token: $token, url: $url, poiTitle: $poiTitle, createdAt: $createdAt, revokedAt: $revokedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPostcardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.poiTitle, poiTitle) ||
                other.poiTitle == poiTitle) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.revokedAt, revokedAt) ||
                other.revokedAt == revokedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, token, url, poiTitle, createdAt, revokedAt);

  /// Create a copy of MyPostcard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPostcardImplCopyWith<_$MyPostcardImpl> get copyWith =>
      __$$MyPostcardImplCopyWithImpl<_$MyPostcardImpl>(this, _$identity);
}

abstract class _MyPostcard implements MyPostcard {
  const factory _MyPostcard({
    required final String id,
    required final String token,
    required final String url,
    required final String poiTitle,
    required final String createdAt,
    final String? revokedAt,
  }) = _$MyPostcardImpl;

  @override
  String get id;
  @override
  String get token;
  @override
  String get url;
  @override
  String get poiTitle;
  @override
  String get createdAt;
  @override
  String? get revokedAt;

  /// Create a copy of MyPostcard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPostcardImplCopyWith<_$MyPostcardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
