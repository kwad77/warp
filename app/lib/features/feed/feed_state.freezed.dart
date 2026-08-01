// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FeedState {
  List<PoiPin> get nearby => throw _privateConstructorUsedError;
  List<PoiPin> get saved => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of FeedState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedStateCopyWith<FeedState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedStateCopyWith<$Res> {
  factory $FeedStateCopyWith(FeedState value, $Res Function(FeedState) then) =
      _$FeedStateCopyWithImpl<$Res, FeedState>;
  @useResult
  $Res call({
    List<PoiPin> nearby,
    List<PoiPin> saved,
    bool loading,
    String? errorMessage,
  });
}

/// @nodoc
class _$FeedStateCopyWithImpl<$Res, $Val extends FeedState>
    implements $FeedStateCopyWith<$Res> {
  _$FeedStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nearby = null,
    Object? saved = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            nearby: null == nearby
                ? _value.nearby
                : nearby // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            saved: null == saved
                ? _value.saved
                : saved // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            loading: null == loading
                ? _value.loading
                : loading // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeedStateImplCopyWith<$Res>
    implements $FeedStateCopyWith<$Res> {
  factory _$$FeedStateImplCopyWith(
    _$FeedStateImpl value,
    $Res Function(_$FeedStateImpl) then,
  ) = __$$FeedStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<PoiPin> nearby,
    List<PoiPin> saved,
    bool loading,
    String? errorMessage,
  });
}

/// @nodoc
class __$$FeedStateImplCopyWithImpl<$Res>
    extends _$FeedStateCopyWithImpl<$Res, _$FeedStateImpl>
    implements _$$FeedStateImplCopyWith<$Res> {
  __$$FeedStateImplCopyWithImpl(
    _$FeedStateImpl _value,
    $Res Function(_$FeedStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nearby = null,
    Object? saved = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$FeedStateImpl(
        nearby: null == nearby
            ? _value._nearby
            : nearby // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        saved: null == saved
            ? _value._saved
            : saved // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        loading: null == loading
            ? _value.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$FeedStateImpl implements _FeedState {
  const _$FeedStateImpl({
    final List<PoiPin> nearby = const [],
    final List<PoiPin> saved = const [],
    this.loading = false,
    this.errorMessage,
  }) : _nearby = nearby,
       _saved = saved;

  final List<PoiPin> _nearby;
  @override
  @JsonKey()
  List<PoiPin> get nearby {
    if (_nearby is EqualUnmodifiableListView) return _nearby;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nearby);
  }

  final List<PoiPin> _saved;
  @override
  @JsonKey()
  List<PoiPin> get saved {
    if (_saved is EqualUnmodifiableListView) return _saved;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_saved);
  }

  @override
  @JsonKey()
  final bool loading;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'FeedState(nearby: $nearby, saved: $saved, loading: $loading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedStateImpl &&
            const DeepCollectionEquality().equals(other._nearby, _nearby) &&
            const DeepCollectionEquality().equals(other._saved, _saved) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_nearby),
    const DeepCollectionEquality().hash(_saved),
    loading,
    errorMessage,
  );

  /// Create a copy of FeedState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedStateImplCopyWith<_$FeedStateImpl> get copyWith =>
      __$$FeedStateImplCopyWithImpl<_$FeedStateImpl>(this, _$identity);
}

abstract class _FeedState implements FeedState {
  const factory _FeedState({
    final List<PoiPin> nearby,
    final List<PoiPin> saved,
    final bool loading,
    final String? errorMessage,
  }) = _$FeedStateImpl;

  @override
  List<PoiPin> get nearby;
  @override
  List<PoiPin> get saved;
  @override
  bool get loading;
  @override
  String? get errorMessage;

  /// Create a copy of FeedState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedStateImplCopyWith<_$FeedStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
