// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coverage_heatmap_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CoverageHeatmapResult {
  List<CoverageHeatmapCell> get cells => throw _privateConstructorUsedError;
  int? get resolution => throw _privateConstructorUsedError;

  /// Create a copy of CoverageHeatmapResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverageHeatmapResultCopyWith<CoverageHeatmapResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageHeatmapResultCopyWith<$Res> {
  factory $CoverageHeatmapResultCopyWith(
    CoverageHeatmapResult value,
    $Res Function(CoverageHeatmapResult) then,
  ) = _$CoverageHeatmapResultCopyWithImpl<$Res, CoverageHeatmapResult>;
  @useResult
  $Res call({List<CoverageHeatmapCell> cells, int? resolution});
}

/// @nodoc
class _$CoverageHeatmapResultCopyWithImpl<
  $Res,
  $Val extends CoverageHeatmapResult
>
    implements $CoverageHeatmapResultCopyWith<$Res> {
  _$CoverageHeatmapResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverageHeatmapResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? cells = null, Object? resolution = freezed}) {
    return _then(
      _value.copyWith(
            cells: null == cells
                ? _value.cells
                : cells // ignore: cast_nullable_to_non_nullable
                      as List<CoverageHeatmapCell>,
            resolution: freezed == resolution
                ? _value.resolution
                : resolution // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CoverageHeatmapResultImplCopyWith<$Res>
    implements $CoverageHeatmapResultCopyWith<$Res> {
  factory _$$CoverageHeatmapResultImplCopyWith(
    _$CoverageHeatmapResultImpl value,
    $Res Function(_$CoverageHeatmapResultImpl) then,
  ) = __$$CoverageHeatmapResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CoverageHeatmapCell> cells, int? resolution});
}

/// @nodoc
class __$$CoverageHeatmapResultImplCopyWithImpl<$Res>
    extends
        _$CoverageHeatmapResultCopyWithImpl<$Res, _$CoverageHeatmapResultImpl>
    implements _$$CoverageHeatmapResultImplCopyWith<$Res> {
  __$$CoverageHeatmapResultImplCopyWithImpl(
    _$CoverageHeatmapResultImpl _value,
    $Res Function(_$CoverageHeatmapResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverageHeatmapResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? cells = null, Object? resolution = freezed}) {
    return _then(
      _$CoverageHeatmapResultImpl(
        cells: null == cells
            ? _value._cells
            : cells // ignore: cast_nullable_to_non_nullable
                  as List<CoverageHeatmapCell>,
        resolution: freezed == resolution
            ? _value.resolution
            : resolution // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$CoverageHeatmapResultImpl implements _CoverageHeatmapResult {
  const _$CoverageHeatmapResultImpl({
    required final List<CoverageHeatmapCell> cells,
    this.resolution,
  }) : _cells = cells;

  final List<CoverageHeatmapCell> _cells;
  @override
  List<CoverageHeatmapCell> get cells {
    if (_cells is EqualUnmodifiableListView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cells);
  }

  @override
  final int? resolution;

  @override
  String toString() {
    return 'CoverageHeatmapResult(cells: $cells, resolution: $resolution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageHeatmapResultImpl &&
            const DeepCollectionEquality().equals(other._cells, _cells) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_cells),
    resolution,
  );

  /// Create a copy of CoverageHeatmapResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageHeatmapResultImplCopyWith<_$CoverageHeatmapResultImpl>
  get copyWith =>
      __$$CoverageHeatmapResultImplCopyWithImpl<_$CoverageHeatmapResultImpl>(
        this,
        _$identity,
      );
}

abstract class _CoverageHeatmapResult implements CoverageHeatmapResult {
  const factory _CoverageHeatmapResult({
    required final List<CoverageHeatmapCell> cells,
    final int? resolution,
  }) = _$CoverageHeatmapResultImpl;

  @override
  List<CoverageHeatmapCell> get cells;
  @override
  int? get resolution;

  /// Create a copy of CoverageHeatmapResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverageHeatmapResultImplCopyWith<_$CoverageHeatmapResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}
