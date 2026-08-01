// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MapViewState {
  PoisResult get result => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of MapViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapViewStateCopyWith<MapViewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapViewStateCopyWith<$Res> {
  factory $MapViewStateCopyWith(
    MapViewState value,
    $Res Function(MapViewState) then,
  ) = _$MapViewStateCopyWithImpl<$Res, MapViewState>;
  @useResult
  $Res call({PoisResult result, bool loading, String? errorMessage});

  $PoisResultCopyWith<$Res> get result;
}

/// @nodoc
class _$MapViewStateCopyWithImpl<$Res, $Val extends MapViewState>
    implements $MapViewStateCopyWith<$Res> {
  _$MapViewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            result: null == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as PoisResult,
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

  /// Create a copy of MapViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PoisResultCopyWith<$Res> get result {
    return $PoisResultCopyWith<$Res>(_value.result, (value) {
      return _then(_value.copyWith(result: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapViewStateImplCopyWith<$Res>
    implements $MapViewStateCopyWith<$Res> {
  factory _$$MapViewStateImplCopyWith(
    _$MapViewStateImpl value,
    $Res Function(_$MapViewStateImpl) then,
  ) = __$$MapViewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PoisResult result, bool loading, String? errorMessage});

  @override
  $PoisResultCopyWith<$Res> get result;
}

/// @nodoc
class __$$MapViewStateImplCopyWithImpl<$Res>
    extends _$MapViewStateCopyWithImpl<$Res, _$MapViewStateImpl>
    implements _$$MapViewStateImplCopyWith<$Res> {
  __$$MapViewStateImplCopyWithImpl(
    _$MapViewStateImpl _value,
    $Res Function(_$MapViewStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MapViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$MapViewStateImpl(
        result: null == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as PoisResult,
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

class _$MapViewStateImpl implements _MapViewState {
  const _$MapViewStateImpl({
    this.result = const PoisResult(pois: [], clusters: []),
    this.loading = false,
    this.errorMessage,
  });

  @override
  @JsonKey()
  final PoisResult result;
  @override
  @JsonKey()
  final bool loading;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'MapViewState(result: $result, loading: $loading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapViewStateImpl &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, result, loading, errorMessage);

  /// Create a copy of MapViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapViewStateImplCopyWith<_$MapViewStateImpl> get copyWith =>
      __$$MapViewStateImplCopyWithImpl<_$MapViewStateImpl>(this, _$identity);
}

abstract class _MapViewState implements MapViewState {
  const factory _MapViewState({
    final PoisResult result,
    final bool loading,
    final String? errorMessage,
  }) = _$MapViewStateImpl;

  @override
  PoisResult get result;
  @override
  bool get loading;
  @override
  String? get errorMessage;

  /// Create a copy of MapViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapViewStateImplCopyWith<_$MapViewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
