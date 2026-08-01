import 'package:geolocator/geolocator.dart';

import '../../models/gps_fix.dart';

/// SPEC §13.1/§13.2 — GPS fixes for POI creation's single `gpsFix` and check-in's
/// `MIN_FIXES..MAX_FIXES` gathering (SPEC §5.1). Owning this small interface (instead of
/// depending on `Geolocator` directly) keeps controllers unit-testable without a real
/// device/emulator, matching `SecureStore`/`FaceGate`.
abstract class LocationSource {
  Future<GpsFix> currentFix();

  /// A continuous stream of fixes for check-in's `FixCollector` (SPEC §13.2). The real
  /// implementation never terminates on its own — callers apply their own timeout.
  Stream<GpsFix> fixStream();
}

class GeolocatorLocationSource implements LocationSource {
  Future<void> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }
  }

  GpsFix _toFix(Position position) => GpsFix(
        lat: position.latitude,
        lng: position.longitude,
        accuracyM: position.accuracy,
        capturedAt: position.timestamp,
      );

  @override
  Future<GpsFix> currentFix() async {
    await _ensurePermission();
    return _toFix(await Geolocator.getCurrentPosition());
  }

  @override
  Stream<GpsFix> fixStream() async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).map(_toFix);
  }
}
