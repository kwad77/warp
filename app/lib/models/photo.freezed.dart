// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Photo {
  String get id => throw _privateConstructorUsedError;
  String get urlCard => throw _privateConstructorUsedError;
  String get urlThumb => throw _privateConstructorUsedError;
  int get voteScore => throw _privateConstructorUsedError;
  bool get myVote => throw _privateConstructorUsedError;
  String get uploaderHandle => throw _privateConstructorUsedError;
  String? get contributorName => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PhotoCopyWith<Photo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoCopyWith<$Res> {
  factory $PhotoCopyWith(Photo value, $Res Function(Photo) then) =
      _$PhotoCopyWithImpl<$Res, Photo>;
  @useResult
  $Res call({
    String id,
    String urlCard,
    String urlThumb,
    int voteScore,
    bool myVote,
    String uploaderHandle,
    String? contributorName,
    String status,
  });
}

/// @nodoc
class _$PhotoCopyWithImpl<$Res, $Val extends Photo>
    implements $PhotoCopyWith<$Res> {
  _$PhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? urlCard = null,
    Object? urlThumb = null,
    Object? voteScore = null,
    Object? myVote = null,
    Object? uploaderHandle = null,
    Object? contributorName = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            urlCard: null == urlCard
                ? _value.urlCard
                : urlCard // ignore: cast_nullable_to_non_nullable
                      as String,
            urlThumb: null == urlThumb
                ? _value.urlThumb
                : urlThumb // ignore: cast_nullable_to_non_nullable
                      as String,
            voteScore: null == voteScore
                ? _value.voteScore
                : voteScore // ignore: cast_nullable_to_non_nullable
                      as int,
            myVote: null == myVote
                ? _value.myVote
                : myVote // ignore: cast_nullable_to_non_nullable
                      as bool,
            uploaderHandle: null == uploaderHandle
                ? _value.uploaderHandle
                : uploaderHandle // ignore: cast_nullable_to_non_nullable
                      as String,
            contributorName: freezed == contributorName
                ? _value.contributorName
                : contributorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PhotoImplCopyWith<$Res> implements $PhotoCopyWith<$Res> {
  factory _$$PhotoImplCopyWith(
    _$PhotoImpl value,
    $Res Function(_$PhotoImpl) then,
  ) = __$$PhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String urlCard,
    String urlThumb,
    int voteScore,
    bool myVote,
    String uploaderHandle,
    String? contributorName,
    String status,
  });
}

/// @nodoc
class __$$PhotoImplCopyWithImpl<$Res>
    extends _$PhotoCopyWithImpl<$Res, _$PhotoImpl>
    implements _$$PhotoImplCopyWith<$Res> {
  __$$PhotoImplCopyWithImpl(
    _$PhotoImpl _value,
    $Res Function(_$PhotoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? urlCard = null,
    Object? urlThumb = null,
    Object? voteScore = null,
    Object? myVote = null,
    Object? uploaderHandle = null,
    Object? contributorName = freezed,
    Object? status = null,
  }) {
    return _then(
      _$PhotoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        urlCard: null == urlCard
            ? _value.urlCard
            : urlCard // ignore: cast_nullable_to_non_nullable
                  as String,
        urlThumb: null == urlThumb
            ? _value.urlThumb
            : urlThumb // ignore: cast_nullable_to_non_nullable
                  as String,
        voteScore: null == voteScore
            ? _value.voteScore
            : voteScore // ignore: cast_nullable_to_non_nullable
                  as int,
        myVote: null == myVote
            ? _value.myVote
            : myVote // ignore: cast_nullable_to_non_nullable
                  as bool,
        uploaderHandle: null == uploaderHandle
            ? _value.uploaderHandle
            : uploaderHandle // ignore: cast_nullable_to_non_nullable
                  as String,
        contributorName: freezed == contributorName
            ? _value.contributorName
            : contributorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PhotoImpl implements _Photo {
  const _$PhotoImpl({
    required this.id,
    required this.urlCard,
    required this.urlThumb,
    required this.voteScore,
    required this.myVote,
    required this.uploaderHandle,
    this.contributorName,
    required this.status,
  });

  @override
  final String id;
  @override
  final String urlCard;
  @override
  final String urlThumb;
  @override
  final int voteScore;
  @override
  final bool myVote;
  @override
  final String uploaderHandle;
  @override
  final String? contributorName;
  @override
  final String status;

  @override
  String toString() {
    return 'Photo(id: $id, urlCard: $urlCard, urlThumb: $urlThumb, voteScore: $voteScore, myVote: $myVote, uploaderHandle: $uploaderHandle, contributorName: $contributorName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.urlCard, urlCard) || other.urlCard == urlCard) &&
            (identical(other.urlThumb, urlThumb) ||
                other.urlThumb == urlThumb) &&
            (identical(other.voteScore, voteScore) ||
                other.voteScore == voteScore) &&
            (identical(other.myVote, myVote) || other.myVote == myVote) &&
            (identical(other.uploaderHandle, uploaderHandle) ||
                other.uploaderHandle == uploaderHandle) &&
            (identical(other.contributorName, contributorName) ||
                other.contributorName == contributorName) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    urlCard,
    urlThumb,
    voteScore,
    myVote,
    uploaderHandle,
    contributorName,
    status,
  );

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      __$$PhotoImplCopyWithImpl<_$PhotoImpl>(this, _$identity);
}

abstract class _Photo implements Photo {
  const factory _Photo({
    required final String id,
    required final String urlCard,
    required final String urlThumb,
    required final int voteScore,
    required final bool myVote,
    required final String uploaderHandle,
    final String? contributorName,
    required final String status,
  }) = _$PhotoImpl;

  @override
  String get id;
  @override
  String get urlCard;
  @override
  String get urlThumb;
  @override
  int get voteScore;
  @override
  bool get myVote;
  @override
  String get uploaderHandle;
  @override
  String? get contributorName;
  @override
  String get status;

  /// Create a copy of Photo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
