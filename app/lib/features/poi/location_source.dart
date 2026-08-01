import 'package:geolocator/geolocator.dart';

import '../../models/gps_fix.dart';

/// SPEC §13.1 — a single best-effort GPS fix for POI creation's `gpsFix`. The check-in
/// flow (SPEC §5.1, `MIN_FIXES..MAX_FIXES`) builds its multi-fix gathering on the same
/// `geolocator` dependency, not this interface directly. Owning this small interface
/// (instead of depending on `Geolocator` directly) keeps the controller unit-testable
/// without a real device/emulator, matching `SecureStore`/`FaceGate`.
abstract class LocationSource {
  Future<GpsFix> currentFix();
}

class GeolocatorLocationSource implements LocationSource {
  @override
  Future<GpsFix> currentFix() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }
    final position = await Geolocator.getCurrentPosition();
    return GpsFix(
      lat: position.latitude,
      lng: position.longitude,
      accuracyM: position.accuracy,
      capturedAt: position.timestamp,
    );
  }
}
