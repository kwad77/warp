import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import 'my_postcards_state.dart';

/// SPEC §20 — loads `GET /me/postcards` and revokes one via `DELETE /postcards/:id`.
/// Closes the "fast-follow" gap the postcard-sending PR flagged: server-side revoke
/// existed with nothing in the mobile UI to reach it.
class MyPostcardsController extends StateNotifier<MyPostcardsState> {
  final WanderpostApi api;

  MyPostcardsController(this.api) : super(const MyPostcardsState());

  Future<void> load() async {
    state = const MyPostcardsState(loading: true);
    try {
      final postcards = await api.myPostcards();
      state = MyPostcardsState(postcards: postcards);
    } on ApiException catch (e) {
      state = MyPostcardsState(errorMessage: e.message);
    }
  }

  /// Optimistic: marks the row revoked locally (rather than removing it — a revoked
  /// postcard is still shown, per `GET /me/postcards`'s own contract) once the server
  /// call succeeds.
  Future<void> revoke(String postcardId) async {
    try {
      await api.revokePostcard(postcardId);
      state = state.copyWith(
        postcards: [
          for (final p in state.postcards)
            if (p.id == postcardId) p.copyWith(revokedAt: DateTime.now().toIso8601String()) else p,
        ],
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}
