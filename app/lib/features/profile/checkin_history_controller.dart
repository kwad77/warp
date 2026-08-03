import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/wanderpost_api.dart';
import 'checkin_history_state.dart';

/// SPEC §7 — loads `GET /me/checkins`, keyset-paginated. Deliberately shows every status
/// (not just `verified`): a user with a check-in stuck `pending` should at least be able
/// to see it happened, even though nothing yet resolves it (SPEC §5.7, flagged in
/// docs/MILESTONES.md).
class CheckinHistoryController extends StateNotifier<CheckinHistoryState> {
  final WanderpostApi api;

  CheckinHistoryController(this.api) : super(const CheckinHistoryState());

  Future<void> load() async {
    state = const CheckinHistoryState(loading: true);
    try {
      final page = await api.meCheckins();
      state = CheckinHistoryState(items: page.items, nextCursor: page.nextCursor);
    } on ApiException catch (e) {
      state = CheckinHistoryState(errorMessage: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.nextCursor == null) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await api.meCheckins(cursor: state.nextCursor);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        loadingMore: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loadingMore: false, errorMessage: e.message);
    }
  }
}
