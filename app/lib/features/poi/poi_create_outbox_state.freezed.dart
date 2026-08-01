// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_create_outbox_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PoiCreateOutboxState {
  List<QueuedPoiCreation> get items => throw _privateConstructorUsedError;
  bool get replaying => throw _privateConstructorUsedError;

  /// Create a copy of PoiCreateOutboxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiCreateOutboxStateCopyWith<PoiCreateOutboxState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiCreateOutboxStateCopyWith<$Res> {
  factory $PoiCreateOutboxStateCopyWith(
    PoiCreateOutboxState value,
    $Res Function(PoiCreateOutboxState) then,
  ) = _$PoiCreateOutboxStateCopyWithImpl<$Res, PoiCreateOutboxState>;
  @useResult
  $Res call({List<QueuedPoiCreation> items, bool replaying});
}

/// @nodoc
class _$PoiCreateOutboxStateCopyWithImpl<
  $Res,
  $Val extends PoiCreateOutboxState
>
    implements $PoiCreateOutboxStateCopyWith<$Res> {
  _$PoiCreateOutboxStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiCreateOutboxState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null, Object? replaying = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<QueuedPoiCreation>,
            replaying: null == replaying
                ? _value.replaying
                : replaying // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PoiCreateOutboxStateImplCopyWith<$Res>
    implements $PoiCreateOutboxStateCopyWith<$Res> {
  factory _$$PoiCreateOutboxStateImplCopyWith(
    _$PoiCreateOutboxStateImpl value,
    $Res Function(_$PoiCreateOutboxStateImpl) then,
  ) = __$$PoiCreateOutboxStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<QueuedPoiCreation> items, bool replaying});
}

/// @nodoc
class __$$PoiCreateOutboxStateImplCopyWithImpl<$Res>
    extends _$PoiCreateOutboxStateCopyWithImpl<$Res, _$PoiCreateOutboxStateImpl>
    implements _$$PoiCreateOutboxStateImplCopyWith<$Res> {
  __$$PoiCreateOutboxStateImplCopyWithImpl(
    _$PoiCreateOutboxStateImpl _value,
    $Res Function(_$PoiCreateOutboxStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoiCreateOutboxState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null, Object? replaying = null}) {
    return _then(
      _$PoiCreateOutboxStateImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<QueuedPoiCreation>,
        replaying: null == replaying
            ? _value.replaying
            : replaying // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$PoiCreateOutboxStateImpl implements _PoiCreateOutboxState {
  const _$PoiCreateOutboxStateImpl({
    final List<QueuedPoiCreation> items = const [],
    this.replaying = false,
  }) : _items = items;

  final List<QueuedPoiCreation> _items;
  @override
  @JsonKey()
  List<QueuedPoiCreation> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final bool replaying;

  @override
  String toString() {
    return 'PoiCreateOutboxState(items: $items, replaying: $replaying)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiCreateOutboxStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.replaying, replaying) ||
                other.replaying == replaying));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    replaying,
  );

  /// Create a copy of PoiCreateOutboxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiCreateOutboxStateImplCopyWith<_$PoiCreateOutboxStateImpl>
  get copyWith =>
      __$$PoiCreateOutboxStateImplCopyWithImpl<_$PoiCreateOutboxStateImpl>(
        this,
        _$identity,
      );
}

abstract class _PoiCreateOutboxState implements PoiCreateOutboxState {
  const factory _PoiCreateOutboxState({
    final List<QueuedPoiCreation> items,
    final bool replaying,
  }) = _$PoiCreateOutboxStateImpl;

  @override
  List<QueuedPoiCreation> get items;
  @override
  bool get replaying;

  /// Create a copy of PoiCreateOutboxState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiCreateOutboxStateImplCopyWith<_$PoiCreateOutboxStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
