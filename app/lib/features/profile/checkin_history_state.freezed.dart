// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CheckinHistoryState {
  List<CheckinListItem> get items => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  bool get loadingMore => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of CheckinHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckinHistoryStateCopyWith<CheckinHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckinHistoryStateCopyWith<$Res> {
  factory $CheckinHistoryStateCopyWith(
    CheckinHistoryState value,
    $Res Function(CheckinHistoryState) then,
  ) = _$CheckinHistoryStateCopyWithImpl<$Res, CheckinHistoryState>;
  @useResult
  $Res call({
    List<CheckinListItem> items,
    String? nextCursor,
    bool loading,
    bool loadingMore,
    String? errorMessage,
  });
}

/// @nodoc
class _$CheckinHistoryStateCopyWithImpl<$Res, $Val extends CheckinHistoryState>
    implements $CheckinHistoryStateCopyWith<$Res> {
  _$CheckinHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckinHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? nextCursor = freezed,
    Object? loading = null,
    Object? loadingMore = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<CheckinListItem>,
            nextCursor: freezed == nextCursor
                ? _value.nextCursor
                : nextCursor // ignore: cast_nullable_to_non_nullable
                      as String?,
            loading: null == loading
                ? _value.loading
                : loading // ignore: cast_nullable_to_non_nullable
                      as bool,
            loadingMore: null == loadingMore
                ? _value.loadingMore
                : loadingMore // ignore: cast_nullable_to_non_nullable
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
abstract class _$$CheckinHistoryStateImplCopyWith<$Res>
    implements $CheckinHistoryStateCopyWith<$Res> {
  factory _$$CheckinHistoryStateImplCopyWith(
    _$CheckinHistoryStateImpl value,
    $Res Function(_$CheckinHistoryStateImpl) then,
  ) = __$$CheckinHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<CheckinListItem> items,
    String? nextCursor,
    bool loading,
    bool loadingMore,
    String? errorMessage,
  });
}

/// @nodoc
class __$$CheckinHistoryStateImplCopyWithImpl<$Res>
    extends _$CheckinHistoryStateCopyWithImpl<$Res, _$CheckinHistoryStateImpl>
    implements _$$CheckinHistoryStateImplCopyWith<$Res> {
  __$$CheckinHistoryStateImplCopyWithImpl(
    _$CheckinHistoryStateImpl _value,
    $Res Function(_$CheckinHistoryStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CheckinHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? nextCursor = freezed,
    Object? loading = null,
    Object? loadingMore = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$CheckinHistoryStateImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<CheckinListItem>,
        nextCursor: freezed == nextCursor
            ? _value.nextCursor
            : nextCursor // ignore: cast_nullable_to_non_nullable
                  as String?,
        loading: null == loading
            ? _value.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingMore: null == loadingMore
            ? _value.loadingMore
            : loadingMore // ignore: cast_nullable_to_non_nullable
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

class _$CheckinHistoryStateImpl implements _CheckinHistoryState {
  const _$CheckinHistoryStateImpl({
    final List<CheckinListItem> items = const [],
    this.nextCursor,
    this.loading = false,
    this.loadingMore = false,
    this.errorMessage,
  }) : _items = items;

  final List<CheckinListItem> _items;
  @override
  @JsonKey()
  List<CheckinListItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? nextCursor;
  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final bool loadingMore;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'CheckinHistoryState(items: $items, nextCursor: $nextCursor, loading: $loading, loadingMore: $loadingMore, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckinHistoryStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.loadingMore, loadingMore) ||
                other.loadingMore == loadingMore) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    nextCursor,
    loading,
    loadingMore,
    errorMessage,
  );

  /// Create a copy of CheckinHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckinHistoryStateImplCopyWith<_$CheckinHistoryStateImpl> get copyWith =>
      __$$CheckinHistoryStateImplCopyWithImpl<_$CheckinHistoryStateImpl>(
        this,
        _$identity,
      );
}

abstract class _CheckinHistoryState implements CheckinHistoryState {
  const factory _CheckinHistoryState({
    final List<CheckinListItem> items,
    final String? nextCursor,
    final bool loading,
    final bool loadingMore,
    final String? errorMessage,
  }) = _$CheckinHistoryStateImpl;

  @override
  List<CheckinListItem> get items;
  @override
  String? get nextCursor;
  @override
  bool get loading;
  @override
  bool get loadingMore;
  @override
  String? get errorMessage;

  /// Create a copy of CheckinHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckinHistoryStateImplCopyWith<_$CheckinHistoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
