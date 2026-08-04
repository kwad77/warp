// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_postcards_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MyPostcardsState {
  List<MyPostcard> get postcards => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of MyPostcardsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyPostcardsStateCopyWith<MyPostcardsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPostcardsStateCopyWith<$Res> {
  factory $MyPostcardsStateCopyWith(
    MyPostcardsState value,
    $Res Function(MyPostcardsState) then,
  ) = _$MyPostcardsStateCopyWithImpl<$Res, MyPostcardsState>;
  @useResult
  $Res call({List<MyPostcard> postcards, bool loading, String? errorMessage});
}

/// @nodoc
class _$MyPostcardsStateCopyWithImpl<$Res, $Val extends MyPostcardsState>
    implements $MyPostcardsStateCopyWith<$Res> {
  _$MyPostcardsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyPostcardsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postcards = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            postcards: null == postcards
                ? _value.postcards
                : postcards // ignore: cast_nullable_to_non_nullable
                      as List<MyPostcard>,
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
abstract class _$$MyPostcardsStateImplCopyWith<$Res>
    implements $MyPostcardsStateCopyWith<$Res> {
  factory _$$MyPostcardsStateImplCopyWith(
    _$MyPostcardsStateImpl value,
    $Res Function(_$MyPostcardsStateImpl) then,
  ) = __$$MyPostcardsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MyPostcard> postcards, bool loading, String? errorMessage});
}

/// @nodoc
class __$$MyPostcardsStateImplCopyWithImpl<$Res>
    extends _$MyPostcardsStateCopyWithImpl<$Res, _$MyPostcardsStateImpl>
    implements _$$MyPostcardsStateImplCopyWith<$Res> {
  __$$MyPostcardsStateImplCopyWithImpl(
    _$MyPostcardsStateImpl _value,
    $Res Function(_$MyPostcardsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MyPostcardsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postcards = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$MyPostcardsStateImpl(
        postcards: null == postcards
            ? _value._postcards
            : postcards // ignore: cast_nullable_to_non_nullable
                  as List<MyPostcard>,
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

class _$MyPostcardsStateImpl implements _MyPostcardsState {
  const _$MyPostcardsStateImpl({
    final List<MyPostcard> postcards = const [],
    this.loading = false,
    this.errorMessage,
  }) : _postcards = postcards;

  final List<MyPostcard> _postcards;
  @override
  @JsonKey()
  List<MyPostcard> get postcards {
    if (_postcards is EqualUnmodifiableListView) return _postcards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_postcards);
  }

  @override
  @JsonKey()
  final bool loading;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'MyPostcardsState(postcards: $postcards, loading: $loading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPostcardsStateImpl &&
            const DeepCollectionEquality().equals(
              other._postcards,
              _postcards,
            ) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_postcards),
    loading,
    errorMessage,
  );

  /// Create a copy of MyPostcardsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPostcardsStateImplCopyWith<_$MyPostcardsStateImpl> get copyWith =>
      __$$MyPostcardsStateImplCopyWithImpl<_$MyPostcardsStateImpl>(
        this,
        _$identity,
      );
}

abstract class _MyPostcardsState implements MyPostcardsState {
  const factory _MyPostcardsState({
    final List<MyPostcard> postcards,
    final bool loading,
    final String? errorMessage,
  }) = _$MyPostcardsStateImpl;

  @override
  List<MyPostcard> get postcards;
  @override
  bool get loading;
  @override
  String? get errorMessage;

  /// Create a copy of MyPostcardsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyPostcardsStateImplCopyWith<_$MyPostcardsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
