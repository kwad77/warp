import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/queued_poi_creation.dart';

part 'poi_create_outbox_state.freezed.dart';

/// SPEC §18 — mirrors `checkin/CheckinOutboxState` (SPEC §17).
@freezed
class PoiCreateOutboxState with _$PoiCreateOutboxState {
  const factory PoiCreateOutboxState({
    @Default([]) List<QueuedPoiCreation> items,
    @Default(false) bool replaying,
  }) = _PoiCreateOutboxState;
}
