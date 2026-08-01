// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coverage_heatmap_cell.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CoverageHeatmapCell {
  String get h3 => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  LatLng get centroid => throw _privateConstructorUsedError;

  /// Create a copy of CoverageHeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverageHeatmapCellCopyWith<CoverageHeatmapCell> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageHeatmapCellCopyWith<$Res> {
  factory $CoverageHeatmapCellCopyWith(
    CoverageHeatmapCell value,
    $Res Function(CoverageHeatmapCell) then,
  ) = _$CoverageHeatmapCellCopyWithImpl<$Res, CoverageHeatmapCell>;
  @useResult
  $Res call({String h3, int count, LatLng centroid});

  $LatLngCopyWith<$Res> get centroid;
}

/// @nodoc
class _$CoverageHeatmapCellCopyWithImpl<$Res, $Val extends CoverageHeatmapCell>
    implements $CoverageHeatmapCellCopyWith<$Res> {
  _$CoverageHeatmapCellCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverageHeatmapCell
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

  /// Create a copy of CoverageHeatmapCell
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
abstract class _$$CoverageHeatmapCellImplCopyWith<$Res>
    implements $CoverageHeatmapCellCopyWith<$Res> {
  factory _$$CoverageHeatmapCellImplCopyWith(
    _$CoverageHeatmapCellImpl value,
    $Res Function(_$CoverageHeatmapCellImpl) then,
  ) = __$$CoverageHeatmapCellImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String h3, int count, LatLng centroid});

  @override
  $LatLngCopyWith<$Res> get centroid;
}

/// @nodoc
class __$$CoverageHeatmapCellImplCopyWithImpl<$Res>
    extends _$CoverageHeatmapCellCopyWithImpl<$Res, _$CoverageHeatmapCellImpl>
    implements _$$CoverageHeatmapCellImplCopyWith<$Res> {
  __$$CoverageHeatmapCellImplCopyWithImpl(
    _$CoverageHeatmapCellImpl _value,
    $Res Function(_$CoverageHeatmapCellImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverageHeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? h3 = null,
    Object? count = null,
    Object? centroid = null,
  }) {
    return _then(
      _$CoverageHeatmapCellImpl(
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

class _$CoverageHeatmapCellImpl implements _CoverageHeatmapCell {
  const _$CoverageHeatmapCellImpl({
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
    return 'CoverageHeatmapCell(h3: $h3, count: $count, centroid: $centroid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageHeatmapCellImpl &&
            (identical(other.h3, h3) || other.h3 == h3) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.centroid, centroid) ||
                other.centroid == centroid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, h3, count, centroid);

  /// Create a copy of CoverageHeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageHeatmapCellImplCopyWith<_$CoverageHeatmapCellImpl> get copyWith =>
      __$$CoverageHeatmapCellImplCopyWithImpl<_$CoverageHeatmapCellImpl>(
        this,
        _$identity,
      );
}

abstract class _CoverageHeatmapCell implements CoverageHeatmapCell {
  const factory _CoverageHeatmapCell({
    required final String h3,
    required final int count,
    required final LatLng centroid,
  }) = _$CoverageHeatmapCellImpl;

  @override
  String get h3;
  @override
  int get count;
  @override
  LatLng get centroid;

  /// Create a copy of CoverageHeatmapCell
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverageHeatmapCellImplCopyWith<_$CoverageHeatmapCellImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
