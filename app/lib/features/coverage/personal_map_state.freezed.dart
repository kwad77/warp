// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_map_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PersonalMapState {
  PersonalMapMode get mode => throw _privateConstructorUsedError;
  List<CoverageHeatmapCell> get heatmapCells =>
      throw _privateConstructorUsedError;
  List<PoiPin> get myPostcards => throw _privateConstructorUsedError;
  List<PoiPin> get nearbyPois => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of PersonalMapState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalMapStateCopyWith<PersonalMapState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalMapStateCopyWith<$Res> {
  factory $PersonalMapStateCopyWith(
    PersonalMapState value,
    $Res Function(PersonalMapState) then,
  ) = _$PersonalMapStateCopyWithImpl<$Res, PersonalMapState>;
  @useResult
  $Res call({
    PersonalMapMode mode,
    List<CoverageHeatmapCell> heatmapCells,
    List<PoiPin> myPostcards,
    List<PoiPin> nearbyPois,
    bool loading,
    String? errorMessage,
  });
}

/// @nodoc
class _$PersonalMapStateCopyWithImpl<$Res, $Val extends PersonalMapState>
    implements $PersonalMapStateCopyWith<$Res> {
  _$PersonalMapStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonalMapState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? heatmapCells = null,
    Object? myPostcards = null,
    Object? nearbyPois = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as PersonalMapMode,
            heatmapCells: null == heatmapCells
                ? _value.heatmapCells
                : heatmapCells // ignore: cast_nullable_to_non_nullable
                      as List<CoverageHeatmapCell>,
            myPostcards: null == myPostcards
                ? _value.myPostcards
                : myPostcards // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            nearbyPois: null == nearbyPois
                ? _value.nearbyPois
                : nearbyPois // ignore: cast_nullable_to_non_nullable
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
abstract class _$$PersonalMapStateImplCopyWith<$Res>
    implements $PersonalMapStateCopyWith<$Res> {
  factory _$$PersonalMapStateImplCopyWith(
    _$PersonalMapStateImpl value,
    $Res Function(_$PersonalMapStateImpl) then,
  ) = __$$PersonalMapStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PersonalMapMode mode,
    List<CoverageHeatmapCell> heatmapCells,
    List<PoiPin> myPostcards,
    List<PoiPin> nearbyPois,
    bool loading,
    String? errorMessage,
  });
}

/// @nodoc
class __$$PersonalMapStateImplCopyWithImpl<$Res>
    extends _$PersonalMapStateCopyWithImpl<$Res, _$PersonalMapStateImpl>
    implements _$$PersonalMapStateImplCopyWith<$Res> {
  __$$PersonalMapStateImplCopyWithImpl(
    _$PersonalMapStateImpl _value,
    $Res Function(_$PersonalMapStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PersonalMapState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? heatmapCells = null,
    Object? myPostcards = null,
    Object? nearbyPois = null,
    Object? loading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$PersonalMapStateImpl(
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as PersonalMapMode,
        heatmapCells: null == heatmapCells
            ? _value._heatmapCells
            : heatmapCells // ignore: cast_nullable_to_non_nullable
                  as List<CoverageHeatmapCell>,
        myPostcards: null == myPostcards
            ? _value._myPostcards
            : myPostcards // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        nearbyPois: null == nearbyPois
            ? _value._nearbyPois
            : nearbyPois // ignore: cast_nullable_to_non_nullable
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

class _$PersonalMapStateImpl implements _PersonalMapState {
  const _$PersonalMapStateImpl({
    this.mode = PersonalMapMode.heatmap,
    final List<CoverageHeatmapCell> heatmapCells = const [],
    final List<PoiPin> myPostcards = const [],
    final List<PoiPin> nearbyPois = const [],
    this.loading = false,
    this.errorMessage,
  }) : _heatmapCells = heatmapCells,
       _myPostcards = myPostcards,
       _nearbyPois = nearbyPois;

  @override
  @JsonKey()
  final PersonalMapMode mode;
  final List<CoverageHeatmapCell> _heatmapCells;
  @override
  @JsonKey()
  List<CoverageHeatmapCell> get heatmapCells {
    if (_heatmapCells is EqualUnmodifiableListView) return _heatmapCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_heatmapCells);
  }

  final List<PoiPin> _myPostcards;
  @override
  @JsonKey()
  List<PoiPin> get myPostcards {
    if (_myPostcards is EqualUnmodifiableListView) return _myPostcards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_myPostcards);
  }

  final List<PoiPin> _nearbyPois;
  @override
  @JsonKey()
  List<PoiPin> get nearbyPois {
    if (_nearbyPois is EqualUnmodifiableListView) return _nearbyPois;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nearbyPois);
  }

  @override
  @JsonKey()
  final bool loading;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'PersonalMapState(mode: $mode, heatmapCells: $heatmapCells, myPostcards: $myPostcards, nearbyPois: $nearbyPois, loading: $loading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalMapStateImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(
              other._heatmapCells,
              _heatmapCells,
            ) &&
            const DeepCollectionEquality().equals(
              other._myPostcards,
              _myPostcards,
            ) &&
            const DeepCollectionEquality().equals(
              other._nearbyPois,
              _nearbyPois,
            ) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    mode,
    const DeepCollectionEquality().hash(_heatmapCells),
    const DeepCollectionEquality().hash(_myPostcards),
    const DeepCollectionEquality().hash(_nearbyPois),
    loading,
    errorMessage,
  );

  /// Create a copy of PersonalMapState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalMapStateImplCopyWith<_$PersonalMapStateImpl> get copyWith =>
      __$$PersonalMapStateImplCopyWithImpl<_$PersonalMapStateImpl>(
        this,
        _$identity,
      );
}

abstract class _PersonalMapState implements PersonalMapState {
  const factory _PersonalMapState({
    final PersonalMapMode mode,
    final List<CoverageHeatmapCell> heatmapCells,
    final List<PoiPin> myPostcards,
    final List<PoiPin> nearbyPois,
    final bool loading,
    final String? errorMessage,
  }) = _$PersonalMapStateImpl;

  @override
  PersonalMapMode get mode;
  @override
  List<CoverageHeatmapCell> get heatmapCells;
  @override
  List<PoiPin> get myPostcards;
  @override
  List<PoiPin> get nearbyPois;
  @override
  bool get loading;
  @override
  String? get errorMessage;

  /// Create a copy of PersonalMapState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalMapStateImplCopyWith<_$PersonalMapStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
