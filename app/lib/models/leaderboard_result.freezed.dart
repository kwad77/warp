// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LeaderboardResult {
  List<LeaderboardEntry> get entries => throw _privateConstructorUsedError;
  MeStanding? get me => throw _privateConstructorUsedError;

  /// Create a copy of LeaderboardResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaderboardResultCopyWith<LeaderboardResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderboardResultCopyWith<$Res> {
  factory $LeaderboardResultCopyWith(
    LeaderboardResult value,
    $Res Function(LeaderboardResult) then,
  ) = _$LeaderboardResultCopyWithImpl<$Res, LeaderboardResult>;
  @useResult
  $Res call({List<LeaderboardEntry> entries, MeStanding? me});

  $MeStandingCopyWith<$Res>? get me;
}

/// @nodoc
class _$LeaderboardResultCopyWithImpl<$Res, $Val extends LeaderboardResult>
    implements $LeaderboardResultCopyWith<$Res> {
  _$LeaderboardResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeaderboardResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? entries = null, Object? me = freezed}) {
    return _then(
      _value.copyWith(
            entries: null == entries
                ? _value.entries
                : entries // ignore: cast_nullable_to_non_nullable
                      as List<LeaderboardEntry>,
            me: freezed == me
                ? _value.me
                : me // ignore: cast_nullable_to_non_nullable
                      as MeStanding?,
          )
          as $Val,
    );
  }

  /// Create a copy of LeaderboardResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MeStandingCopyWith<$Res>? get me {
    if (_value.me == null) {
      return null;
    }

    return $MeStandingCopyWith<$Res>(_value.me!, (value) {
      return _then(_value.copyWith(me: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LeaderboardResultImplCopyWith<$Res>
    implements $LeaderboardResultCopyWith<$Res> {
  factory _$$LeaderboardResultImplCopyWith(
    _$LeaderboardResultImpl value,
    $Res Function(_$LeaderboardResultImpl) then,
  ) = __$$LeaderboardResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<LeaderboardEntry> entries, MeStanding? me});

  @override
  $MeStandingCopyWith<$Res>? get me;
}

/// @nodoc
class __$$LeaderboardResultImplCopyWithImpl<$Res>
    extends _$LeaderboardResultCopyWithImpl<$Res, _$LeaderboardResultImpl>
    implements _$$LeaderboardResultImplCopyWith<$Res> {
  __$$LeaderboardResultImplCopyWithImpl(
    _$LeaderboardResultImpl _value,
    $Res Function(_$LeaderboardResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeaderboardResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? entries = null, Object? me = freezed}) {
    return _then(
      _$LeaderboardResultImpl(
        entries: null == entries
            ? _value._entries
            : entries // ignore: cast_nullable_to_non_nullable
                  as List<LeaderboardEntry>,
        me: freezed == me
            ? _value.me
            : me // ignore: cast_nullable_to_non_nullable
                  as MeStanding?,
      ),
    );
  }
}

/// @nodoc

class _$LeaderboardResultImpl implements _LeaderboardResult {
  const _$LeaderboardResultImpl({
    required final List<LeaderboardEntry> entries,
    this.me,
  }) : _entries = entries;

  final List<LeaderboardEntry> _entries;
  @override
  List<LeaderboardEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  final MeStanding? me;

  @override
  String toString() {
    return 'LeaderboardResult(entries: $entries, me: $me)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderboardResultImpl &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            (identical(other.me, me) || other.me == me));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_entries),
    me,
  );

  /// Create a copy of LeaderboardResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderboardResultImplCopyWith<_$LeaderboardResultImpl> get copyWith =>
      __$$LeaderboardResultImplCopyWithImpl<_$LeaderboardResultImpl>(
        this,
        _$identity,
      );
}

abstract class _LeaderboardResult implements LeaderboardResult {
  const factory _LeaderboardResult({
    required final List<LeaderboardEntry> entries,
    final MeStanding? me,
  }) = _$LeaderboardResultImpl;

  @override
  List<LeaderboardEntry> get entries;
  @override
  MeStanding? get me;

  /// Create a copy of LeaderboardResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaderboardResultImplCopyWith<_$LeaderboardResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
