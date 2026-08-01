import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/checkin.dart';

part 'checkin_state.freezed.dart';

/// SPEC §13.2 check-in flow states.
@freezed
class CheckinState with _$CheckinState {
  const factory CheckinState.idle() = _Idle;
  const factory CheckinState.inProgress() = _InProgress;
  const factory CheckinState.verified(Checkin checkin) = _Verified;
  const factory CheckinState.pending(Checkin checkin) = _Pending;

  /// `422 checkin/rejected` — `details.reasons` shown as-is (SPEC §13.2).
  const factory CheckinState.rejected(List<String> reasons) = _Rejected;

  /// `409 checkin/duplicate` — not a transient failure, no retry affordance.
  const factory CheckinState.duplicate() = _Duplicate;

  /// A face was detected in the captured photo; never reached the server (SPEC §6).
  const factory CheckinState.photoBlocked() = _PhotoBlocked;

  /// Fewer than `MIN_FIXES` fixes collected before `FIX_WINDOW_MAX_S` elapsed.
  const factory CheckinState.fixTimeout() = _FixTimeout;
  const factory CheckinState.error(String message) = _Error;
}
