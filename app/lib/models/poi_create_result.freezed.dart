// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_create_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PoiCreateResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Poi poi) created,
    required TResult Function(List<PoiPin> candidates) dedupe,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Poi poi)? created,
    TResult? Function(List<PoiPin> candidates)? dedupe,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Poi poi)? created,
    TResult Function(List<PoiPin> candidates)? dedupe,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Created value) created,
    required TResult Function(_Dedupe value) dedupe,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Created value)? created,
    TResult? Function(_Dedupe value)? dedupe,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Created value)? created,
    TResult Function(_Dedupe value)? dedupe,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiCreateResultCopyWith<$Res> {
  factory $PoiCreateResultCopyWith(
    PoiCreateResult value,
    $Res Function(PoiCreateResult) then,
  ) = _$PoiCreateResultCopyWithImpl<$Res, PoiCreateResult>;
}

/// @nodoc
class _$PoiCreateResultCopyWithImpl<$Res, $Val extends PoiCreateResult>
    implements $PoiCreateResultCopyWith<$Res> {
  _$PoiCreateResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$CreatedImplCopyWith<$Res> {
  factory _$$CreatedImplCopyWith(
    _$CreatedImpl value,
    $Res Function(_$CreatedImpl) then,
  ) = __$$CreatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Poi poi});

  $PoiCopyWith<$Res> get poi;
}

/// @nodoc
class __$$CreatedImplCopyWithImpl<$Res>
    extends _$PoiCreateResultCopyWithImpl<$Res, _$CreatedImpl>
    implements _$$CreatedImplCopyWith<$Res> {
  __$$CreatedImplCopyWithImpl(
    _$CreatedImpl _value,
    $Res Function(_$CreatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? poi = null}) {
    return _then(
      _$CreatedImpl(
        null == poi
            ? _value.poi
            : poi // ignore: cast_nullable_to_non_nullable
                  as Poi,
      ),
    );
  }

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PoiCopyWith<$Res> get poi {
    return $PoiCopyWith<$Res>(_value.poi, (value) {
      return _then(_value.copyWith(poi: value));
    });
  }
}

/// @nodoc

class _$CreatedImpl implements _Created {
  const _$CreatedImpl(this.poi);

  @override
  final Poi poi;

  @override
  String toString() {
    return 'PoiCreateResult.created(poi: $poi)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatedImpl &&
            (identical(other.poi, poi) || other.poi == poi));
  }

  @override
  int get hashCode => Object.hash(runtimeType, poi);

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatedImplCopyWith<_$CreatedImpl> get copyWith =>
      __$$CreatedImplCopyWithImpl<_$CreatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Poi poi) created,
    required TResult Function(List<PoiPin> candidates) dedupe,
  }) {
    return created(poi);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Poi poi)? created,
    TResult? Function(List<PoiPin> candidates)? dedupe,
  }) {
    return created?.call(poi);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Poi poi)? created,
    TResult Function(List<PoiPin> candidates)? dedupe,
    required TResult orElse(),
  }) {
    if (created != null) {
      return created(poi);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Created value) created,
    required TResult Function(_Dedupe value) dedupe,
  }) {
    return created(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Created value)? created,
    TResult? Function(_Dedupe value)? dedupe,
  }) {
    return created?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Created value)? created,
    TResult Function(_Dedupe value)? dedupe,
    required TResult orElse(),
  }) {
    if (created != null) {
      return created(this);
    }
    return orElse();
  }
}

abstract class _Created implements PoiCreateResult {
  const factory _Created(final Poi poi) = _$CreatedImpl;

  Poi get poi;

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatedImplCopyWith<_$CreatedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DedupeImplCopyWith<$Res> {
  factory _$$DedupeImplCopyWith(
    _$DedupeImpl value,
    $Res Function(_$DedupeImpl) then,
  ) = __$$DedupeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<PoiPin> candidates});
}

/// @nodoc
class __$$DedupeImplCopyWithImpl<$Res>
    extends _$PoiCreateResultCopyWithImpl<$Res, _$DedupeImpl>
    implements _$$DedupeImplCopyWith<$Res> {
  __$$DedupeImplCopyWithImpl(
    _$DedupeImpl _value,
    $Res Function(_$DedupeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? candidates = null}) {
    return _then(
      _$DedupeImpl(
        null == candidates
            ? _value._candidates
            : candidates // ignore: cast_nullable_to_non_nullable
                  as List<PoiPin>,
      ),
    );
  }
}

/// @nodoc

class _$DedupeImpl implements _Dedupe {
  const _$DedupeImpl(final List<PoiPin> candidates) : _candidates = candidates;

  final List<PoiPin> _candidates;
  @override
  List<PoiPin> get candidates {
    if (_candidates is EqualUnmodifiableListView) return _candidates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_candidates);
  }

  @override
  String toString() {
    return 'PoiCreateResult.dedupe(candidates: $candidates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DedupeImpl &&
            const DeepCollectionEquality().equals(
              other._candidates,
              _candidates,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_candidates),
  );

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DedupeImplCopyWith<_$DedupeImpl> get copyWith =>
      __$$DedupeImplCopyWithImpl<_$DedupeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Poi poi) created,
    required TResult Function(List<PoiPin> candidates) dedupe,
  }) {
    return dedupe(candidates);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Poi poi)? created,
    TResult? Function(List<PoiPin> candidates)? dedupe,
  }) {
    return dedupe?.call(candidates);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Poi poi)? created,
    TResult Function(List<PoiPin> candidates)? dedupe,
    required TResult orElse(),
  }) {
    if (dedupe != null) {
      return dedupe(candidates);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Created value) created,
    required TResult Function(_Dedupe value) dedupe,
  }) {
    return dedupe(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Created value)? created,
    TResult? Function(_Dedupe value)? dedupe,
  }) {
    return dedupe?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Created value)? created,
    TResult Function(_Dedupe value)? dedupe,
    required TResult orElse(),
  }) {
    if (dedupe != null) {
      return dedupe(this);
    }
    return orElse();
  }
}

abstract class _Dedupe implements PoiCreateResult {
  const factory _Dedupe(final List<PoiPin> candidates) = _$DedupeImpl;

  List<PoiPin> get candidates;

  /// Create a copy of PoiCreateResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DedupeImplCopyWith<_$DedupeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
