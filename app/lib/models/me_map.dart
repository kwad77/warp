import 'package:freezed_annotation/freezed_annotation.dart';

import 'poi_pin.dart';

part 'me_map.freezed.dart';

/// SPEC §7 `GET /me/map`. `vaulted` is always `[]` in M1 — the vault ships M3.
@freezed
class MeMap with _$MeMap {
  const factory MeMap({
    required List<PoiPin> checkedIn,
    required List<PoiPin> created,
    required List<PoiPin> vaulted,
  }) = _MeMap;

  factory MeMap.fromMap(Map<String, dynamic> json) => MeMap(
        checkedIn: (json['checkedIn'] as List<dynamic>)
            .map((e) => PoiPin.fromMap(e as Map<String, dynamic>))
            .toList(),
        created: (json['created'] as List<dynamic>)
            .map((e) => PoiPin.fromMap(e as Map<String, dynamic>))
            .toList(),
        vaulted: (json['vaulted'] as List<dynamic>)
            .map((e) => PoiPin.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}
