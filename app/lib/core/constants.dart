/// SPEC §12 — mobile app constants.
class AppConfig {
  AppConfig._();

  /// Android emulator → host loopback. iOS simulator run instructions use
  /// `--dart-define=API_BASE_URL=http://localhost:8080` (shares host networking).
  /// Plain HTTP to `localhost`/loopback is exempt from iOS App Transport Security by
  /// default (has been since ATS's introduction) — no Info.plist exception was added, and
  /// none should be: a blanket ATS exception is exactly the kind of thing that
  /// accidentally survives into a release build. Production MUST be HTTPS regardless.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// OpenFreeMap, matches ARCHITECTURE.md's MapLibre choice. Pinning a self-hosted style
  /// is a pre-launch hardening item, not blocking for M1.
  static const String mapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  /// Below this zoom, the server returns clusters instead of individual POI pins.
  static const int clusterZoomThreshold = 13;
}
