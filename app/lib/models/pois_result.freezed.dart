// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pois_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PoisResult {
  List<PoiPin> get pois => throw _privateConstructorUsedError;
  List<Cluster> get clusters => throw _privateConstructorUsedError;

  /// Create a copy of PoisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoisResultCopyWith<PoisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoisResultCopyWith<$Res> {
  factory $PoisResultCopyWith(
    PoisResult value,
    $Res Function(PoisResult) then,
  ) = _$PoisResultCopyWithImpl<$Res, PoisResult>;
  @useResult
  $Res call({List<PoiPin> pois, List<Cluster> clusters});
}

/// @nodoc
class _$PoisResultCopyWithImpl<$Res, $Val extends PoisResult>
    implements $PoisResultCopyWith<$Res> {
  _$PoisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pois = null, Object? clusters = null}) {
    return _then(
      _value.copyWith(
            pois: null == pois
                ? _value.pois
                : pois // ignore: cast_nullable_to_non_nullable
                      as List<PoiPin>,
            clusters: null == clusters
                ? _value.clusters
                : clusters // ignore: cast_nullable_to_non_nullable
                      as List<Cluster>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PoisResultImplCopyWith<$Res>
    implements $PoisResultCopyWith<$Res> {
  factory _$$PoisResultImplCopyWith(
    _$PoisResultImpl value,
    $Res Function(_$PoisResultImpl) then,
  ) = __$$PoisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PoiPin> pois, List<Cluster> clusters});
}

/// @nodoc
class __$$PoisResultImplCopyWithImpl<$Res>
    extends _$PoisResultCopyWithImpl<$Res, _$PoisResultImpl>
    implements _$$PoisResultImplCopyWith<$Res> {
  __$$PoisResultImplCopyWithImpl(
    _$PoisResultImpl _value,
    $Res Function(_$PoisResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pois = null, Object? clusters = null}) {
    return _then(
      _$PoisResultImpl(
        pois: null == pois
            ? _value._pois
            : pois // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
        clusters: null == clusters
            ? _value._clusters
            : clusters // ignore: cast_nullable_to_non_nullable
                  as List<Cluster>,
      ),
    );
  }
}

/// @nodoc

class _$PoisResultImpl implements _PoisResult {
  const _$PoisResultImpl({
    required final List<PoiPin> pois,
    required final List<Cluster> clusters,
  }) : _pois = pois,
       _clusters = clusters;

  final List<PoiPin> _pois;
  @override
  List<PoiPin> get pois {
    if (_pois is EqualUnmodifiableListView) return _pois;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pois);
  }

  final List<Cluster> _clusters;
  @override
  List<Cluster> get clusters {
    if (_clusters is EqualUnmodifiableListView) return _clusters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clusters);
  }

  @override
  String toString() {
    return 'PoisResult(pois: $pois, clusters: $clusters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoisResultImpl &&
            const DeepCollectionEquality().equals(other._pois, _pois) &&
            const DeepCollectionEquality().equals(other._clusters, _clusters));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_pois),
    const DeepCollectionEquality().hash(_clusters),
  );

  /// Create a copy of PoisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoisResultImplCopyWith<_$PoisResultImpl> get copyWith =>
      __$$PoisResultImplCopyWithImpl<_$PoisResultImpl>(this, _$identity);
}

abstract class _PoisResult implements PoisResult {
  const factory _PoisResult({
    required final List<PoiPin> pois,
    required final List<Cluster> clusters,
  }) = _$PoisResultImpl;

  @override
  List<PoiPin> get pois;
  @override
  List<Cluster> get clusters;

  /// Create a copy of PoisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoisResultImplCopyWith<_$PoisResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
