// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me_map.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MeMap {
  List<PoiPin> get checkedIn => throw _privateConstructorUsedError;
  List<PoiPin> get created => throw _privateConstructorUsedError;
  List<PoiPin> get saved => throw _privateConstructorUsedError;
  List<PoiPin> get vaulted => throw _privateConstructorUsedError;

  /// Create a copy of MeMap
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeMapCopyWith<MeMap> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeMapCopyWith<$Res> {
  factory $MeMapCopyWith(MeMap value, $Res Function(MeMap) then) =
      _$MeMapCopyWithImpl<$Res, MeMap>;
  @useResult
  $Res call({
    List<PoiPin> checkedIn,
    List<PoiPin> created,
    List<PoiPin> saved,
    List<PoiPin> vaulted,
  });
}

/// @nodoc
class _$MeMapCopyWithImpl<$Res, $Val extends MeMap>
    implements $MeMapCopyWith<$Res> {
  _$MeMapCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeMap
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkedIn = null,
    Object? created = null,
    Object? saved = null,
    Object? vaulted = null,
  }) {
    return _then(
      _value.copyWith(
            checkedIn: null == checkedIn
                ? _value.checkedIn
                : checkedIn // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            created: null == created
                ? _value.created
                : created // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            saved: null == saved
                ? _value.saved
                : saved // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            vaulted: null == vaulted
                ? _value.vaulted
                : vaulted // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MeMapImplCopyWith<$Res> implements $MeMapCopyWith<$Res> {
  factory _$$MeMapImplCopyWith(
    _$MeMapImpl value,
    $Res Function(_$MeMapImpl) then,
  ) = __$$MeMapImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<PoiPin> checkedIn,
    List<PoiPin> created,
    List<PoiPin> saved,
    List<PoiPin> vaulted,
  });
}

/// @nodoc
class __$$MeMapImplCopyWithImpl<$Res>
    extends _$MeMapCopyWithImpl<$Res, _$MeMapImpl>
    implements _$$MeMapImplCopyWith<$Res> {
  __$$MeMapImplCopyWithImpl(
    _$MeMapImpl _value,
    $Res Function(_$MeMapImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MeMap
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkedIn = null,
    Object? created = null,
    Object? saved = null,
    Object? vaulted = null,
  }) {
    return _then(
      _$MeMapImpl(
        checkedIn: null == checkedIn
            ? _value._checkedIn
            : checkedIn // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        created: null == created
            ? _value._created
            : created // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        saved: null == saved
            ? _value._saved
            : saved // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        vaulted: null == vaulted
            ? _value._vaulted
            : vaulted // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
      ),
    );
  }
}

/// @nodoc

class _$MeMapImpl implements _MeMap {
  const _$MeMapImpl({
    required final List<PoiPin> checkedIn,
    required final List<PoiPin> created,
    required final List<PoiPin> saved,
    required final List<PoiPin> vaulted,
  }) : _checkedIn = checkedIn,
       _created = created,
       _saved = saved,
       _vaulted = vaulted;

  final List<PoiPin> _checkedIn;
  @override
  List<PoiPin> get checkedIn {
    if (_checkedIn is EqualUnmodifiableListView) return _checkedIn;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checkedIn);
  }

  final List<PoiPin> _created;
  @override
  List<PoiPin> get created {
    if (_created is EqualUnmodifiableListView) return _created;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_created);
  }

  final List<PoiPin> _saved;
  @override
  List<PoiPin> get saved {
    if (_saved is EqualUnmodifiableListView) return _saved;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_saved);
  }

  final List<PoiPin> _vaulted;
  @override
  List<PoiPin> get vaulted {
    if (_vaulted is EqualUnmodifiableListView) return _vaulted;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vaulted);
  }

  @override
  String toString() {
    return 'MeMap(checkedIn: $checkedIn, created: $created, saved: $saved, vaulted: $vaulted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeMapImpl &&
            const DeepCollectionEquality().equals(
              other._checkedIn,
              _checkedIn,
            ) &&
            const DeepCollectionEquality().equals(other._created, _created) &&
            const DeepCollectionEquality().equals(other._saved, _saved) &&
            const DeepCollectionEquality().equals(other._vaulted, _vaulted));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_checkedIn),
    const DeepCollectionEquality().hash(_created),
    const DeepCollectionEquality().hash(_saved),
    const DeepCollectionEquality().hash(_vaulted),
  );

  /// Create a copy of MeMap
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeMapImplCopyWith<_$MeMapImpl> get copyWith =>
      __$$MeMapImplCopyWithImpl<_$MeMapImpl>(this, _$identity);
}

abstract class _MeMap implements MeMap {
  const factory _MeMap({
    required final List<PoiPin> checkedIn,
    required final List<PoiPin> created,
    required final List<PoiPin> saved,
    required final List<PoiPin> vaulted,
  }) = _$MeMapImpl;

  @override
  List<PoiPin> get checkedIn;
  @override
  List<PoiPin> get created;
  @override
  List<PoiPin> get saved;
  @override
  List<PoiPin> get vaulted;

  /// Create a copy of MeMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeMapImplCopyWith<_$MeMapImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
