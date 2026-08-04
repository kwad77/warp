import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/my_postcard.dart';

part 'my_postcards_state.freezed.dart';

/// SPEC §20 `GET /me/postcards` — the caller's own sent postcards, newest first,
/// including already-revoked ones (so the screen reads as a real history, not a
/// shrinking active set).
@freezed
class MyPostcardsState with _$MyPostcardsState {
  const factory MyPostcardsState({
    @Default([]) List<MyPostcard> postcards,
    @Default(false) bool loading,
    String? errorMessage,
  }) = _MyPostcardsState;
}
