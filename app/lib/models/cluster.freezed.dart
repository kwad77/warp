// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cluster.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Cluster {
  String get h3 => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  LatLng get centroid => throw _privateConstructorUsedError;

  /// Create a copy of Cluster
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClusterCopyWith<Cluster> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClusterCopyWith<$Res> {
  factory $ClusterCopyWith(Cluster value, $Res Function(Cluster) then) =
      _$ClusterCopyWithImpl<$Res, Cluster>;
  @useResult
  $Res call({String h3, int count, LatLng centroid});

  $LatLngCopyWith<$Res> get centroid;
}

/// @nodoc
class _$ClusterCopyWithImpl<$Res, $Val extends Cluster>
    implements $ClusterCopyWith<$Res> {
  _$ClusterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cluster
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? h3 = null,
    Object? count = null,
    Object? centroid = null,
  }) {
    return _then(
      _value.copyWith(
            h3: null == h3
                ? _value.h3
                : h3 // ignore: cast_nullable_to_non_nullable
                      as String,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            centroid: null == centroid
                ? _value.centroid
                : centroid // ignore: cast_nullable_to_non_nullable
                      as LatLng,
          )
          as $Val,
    );
  }

  /// Create a copy of Cluster
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LatLngCopyWith<$Res> get centroid {
    return $LatLngCopyWith<$Res>(_value.centroid, (value) {
      return _then(_value.copyWith(centroid: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClusterImplCopyWith<$Res> implements $ClusterCopyWith<$Res> {
  factory _$$ClusterImplCopyWith(
    _$ClusterImpl value,
    $Res Function(_$ClusterImpl) then,
  ) = __$$ClusterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String h3, int count, LatLng centroid});

  @override
  $LatLngCopyWith<$Res> get centroid;
}

/// @nodoc
class __$$ClusterImplCopyWithImpl<$Res>
    extends _$ClusterCopyWithImpl<$Res, _$ClusterImpl>
    implements _$$ClusterImplCopyWith<$Res> {
  __$$ClusterImplCopyWithImpl(
    _$ClusterImpl _value,
    $Res Function(_$ClusterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Cluster
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? h3 = null,
    Object? count = null,
    Object? centroid = null,
  }) {
    return _then(
      _$ClusterImpl(
        h3: null == h3
            ? _value.h3
            : h3 // ignore: cast_nullable_to_non_nullable
                  as String,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        centroid: null == centroid
            ? _value.centroid
            : centroid // ignore: cast_nullable_to_non_nullable
                  as LatLng,
      ),
    );
  }
}

/// @nodoc

class _$ClusterImpl implements _Cluster {
  const _$ClusterImpl({
    required this.h3,
    required this.count,
    required this.centroid,
  });

  @override
  final String h3;
  @override
  final int count;
  @override
  final LatLng centroid;

  @override
  String toString() {
    return 'Cluster(h3: $h3, count: $count, centroid: $centroid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClusterImpl &&
            (identical(other.h3, h3) || other.h3 == h3) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.centroid, centroid) ||
                other.centroid == centroid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, h3, count, centroid);

  /// Create a copy of Cluster
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClusterImplCopyWith<_$ClusterImpl> get copyWith =>
      __$$ClusterImplCopyWithImpl<_$ClusterImpl>(this, _$identity);
}

abstract class _Cluster implements Cluster {
  const factory _Cluster({
    required final String h3,
    required final int count,
    required final LatLng centroid,
  }) = _$ClusterImpl;

  @override
  String get h3;
  @override
  int get count;
  @override
  LatLng get centroid;

  /// Create a copy of Cluster
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClusterImplCopyWith<_$ClusterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
