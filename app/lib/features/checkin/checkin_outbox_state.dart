import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/queued_checkin.dart';

part 'checkin_outbox_state.freezed.dart';

/// SPEC §17 — the outbox's own observable state, for a "pending sync" affordance and to
/// drive replay.
@freezed
class CheckinOutboxState with _$CheckinOutboxState {
  const factory CheckinOutboxState({
    @Default([]) List<QueuedCheckin> items,
    @Default(false) bool replaying,
  }) = _CheckinOutboxState;
}
