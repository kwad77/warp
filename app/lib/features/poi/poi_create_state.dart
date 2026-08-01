import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/poi.dart';
import '../../models/poi_pin.dart';

part 'poi_create_state.freezed.dart';

/// SPEC §13.1 POI-creation flow states.
@freezed
class PoiCreateState with _$PoiCreateState {
  const factory PoiCreateState.editing() = _Editing;
  const factory PoiCreateState.submitting() = _Submitting;
  const factory PoiCreateState.created(Poi poi) = _Created;
  const factory PoiCreateState.dedupe(List<PoiPin> candidates) = _Dedupe;

  /// `422 poi/outside_pin_adjust` — surfaced as an inline pin error, not the generic
  /// error state (SPEC §13.1).
  const factory PoiCreateState.pinAdjustError() = _PinAdjustError;

  /// A face was detected in the captured/picked photo; the submission never reached the
  /// server (SPEC §6 — the gate runs before upload).
  const factory PoiCreateState.photoBlocked() = _PhotoBlocked;

  /// `resizeForUpload` couldn't decode the photo (e.g. HEIC) — checked before any
  /// network call, same as `photoBlocked` (SPEC §13.1).
  const factory PoiCreateState.photoProcessingFailed() = _PhotoProcessingFailed;
  const factory PoiCreateState.error(String message) = _Error;

  /// SPEC §18 — `POST /pois` failed with no connectivity; captured locally and queued in
  /// the offline outbox instead of erroring outright. Terminal, like `created` — the
  /// caller finds out the real outcome once the outbox replays.
  const factory PoiCreateState.queued() = _Queued;
}
