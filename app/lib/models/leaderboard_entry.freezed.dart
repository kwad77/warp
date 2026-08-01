// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LeaderboardEntry {
  int get rank => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  int get cells => throw _privateConstructorUsedError;

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaderboardEntryCopyWith<LeaderboardEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderboardEntryCopyWith<$Res> {
  factory $LeaderboardEntryCopyWith(
    LeaderboardEntry value,
    $Res Function(LeaderboardEntry) then,
  ) = _$LeaderboardEntryCopyWithImpl<$Res, LeaderboardEntry>;
  @useResult
  $Res call({int rank, String handle, int cells});
}

/// @nodoc
class _$LeaderboardEntryCopyWithImpl<$Res, $Val extends LeaderboardEntry>
    implements $LeaderboardEntryCopyWith<$Res> {
  _$LeaderboardEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? handle = null,
    Object? cells = null,
  }) {
    return _then(
      _value.copyWith(
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as int,
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
            cells: null == cells
                ? _value.cells
                : cells // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LeaderboardEntryImplCopyWith<$Res>
    implements $LeaderboardEntryCopyWith<$Res> {
  factory _$$LeaderboardEntryImplCopyWith(
    _$LeaderboardEntryImpl value,
    $Res Function(_$LeaderboardEntryImpl) then,
  ) = __$$LeaderboardEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int rank, String handle, int cells});
}

/// @nodoc
class __$$LeaderboardEntryImplCopyWithImpl<$Res>
    extends _$LeaderboardEntryCopyWithImpl<$Res, _$LeaderboardEntryImpl>
    implements _$$LeaderboardEntryImplCopyWith<$Res> {
  __$$LeaderboardEntryImplCopyWithImpl(
    _$LeaderboardEntryImpl _value,
    $Res Function(_$LeaderboardEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? handle = null,
    Object? cells = null,
  }) {
    return _then(
      _$LeaderboardEntryImpl(
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as int,
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
        cells: null == cells
            ? _value.cells
            : cells // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$LeaderboardEntryImpl implements _LeaderboardEntry {
  const _$LeaderboardEntryImpl({
    required this.rank,
    required this.handle,
    required this.cells,
  });

  @override
  final int rank;
  @override
  final String handle;
  @override
  final int cells;

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, handle: $handle, cells: $cells)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderboardEntryImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.cells, cells) || other.cells == cells));
  }

  @override
  int get hashCode => Object.hash(runtimeType, rank, handle, cells);

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderboardEntryImplCopyWith<_$LeaderboardEntryImpl> get copyWith =>
      __$$LeaderboardEntryImplCopyWithImpl<_$LeaderboardEntryImpl>(
        this,
        _$identity,
      );
}

abstract class _LeaderboardEntry implements LeaderboardEntry {
  const factory _LeaderboardEntry({
    required final int rank,
    required final String handle,
    required final int cells,
  }) = _$LeaderboardEntryImpl;

  @override
  int get rank;
  @override
  String get handle;
  @override
  int get cells;

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaderboardEntryImplCopyWith<_$LeaderboardEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MeStanding {
  int get rank => throw _privateConstructorUsedError;
  int get cells => throw _privateConstructorUsedError;

  /// Create a copy of MeStanding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeStandingCopyWith<MeStanding> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeStandingCopyWith<$Res> {
  factory $MeStandingCopyWith(
    MeStanding value,
    $Res Function(MeStanding) then,
  ) = _$MeStandingCopyWithImpl<$Res, MeStanding>;
  @useResult
  $Res call({int rank, int cells});
}

/// @nodoc
class _$MeStandingCopyWithImpl<$Res, $Val extends MeStanding>
    implements $MeStandingCopyWith<$Res> {
  _$MeStandingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeStanding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rank = null, Object? cells = null}) {
    return _then(
      _value.copyWith(
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as int,
            cells: null == cells
                ? _value.cells
                : cells // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MeStandingImplCopyWith<$Res>
    implements $MeStandingCopyWith<$Res> {
  factory _$$MeStandingImplCopyWith(
    _$MeStandingImpl value,
    $Res Function(_$MeStandingImpl) then,
  ) = __$$MeStandingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int rank, int cells});
}

/// @nodoc
class __$$MeStandingImplCopyWithImpl<$Res>
    extends _$MeStandingCopyWithImpl<$Res, _$MeStandingImpl>
    implements _$$MeStandingImplCopyWith<$Res> {
  __$$MeStandingImplCopyWithImpl(
    _$MeStandingImpl _value,
    $Res Function(_$MeStandingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MeStanding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rank = null, Object? cells = null}) {
    return _then(
      _$MeStandingImpl(
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as int,
        cells: null == cells
            ? _value.cells
            : cells // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$MeStandingImpl implements _MeStanding {
  const _$MeStandingImpl({required this.rank, required this.cells});

  @override
  final int rank;
  @override
  final int cells;

  @override
  String toString() {
    return 'MeStanding(rank: $rank, cells: $cells)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeStandingImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.cells, cells) || other.cells == cells));
  }

  @override
  int get hashCode => Object.hash(runtimeType, rank, cells);

  /// Create a copy of MeStanding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeStandingImplCopyWith<_$MeStandingImpl> get copyWith =>
      __$$MeStandingImplCopyWithImpl<_$MeStandingImpl>(this, _$identity);
}

abstract class _MeStanding implements MeStanding {
  const factory _MeStanding({
    required final int rank,
    required final int cells,
  }) = _$MeStandingImpl;

  @override
  int get rank;
  @override
  int get cells;

  /// Create a copy of MeStanding
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeStandingImplCopyWith<_$MeStandingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
