import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/checkin_list_item.dart';

part 'checkin_history_state.freezed.dart';

/// SPEC §7 `GET /me/checkins` — the caller's own check-in history, every status
/// included (`verified`/`pending`/`rejected`), keyset-paginated.
@freezed
class CheckinHistoryState with _$CheckinHistoryState {
  const factory CheckinHistoryState({
    @Default([]) List<CheckinListItem> items,
    String? nextCursor,
    @Default(false) bool loading,
    @Default(false) bool loadingMore,
    String? errorMessage,
  }) = _CheckinHistoryState;
}
