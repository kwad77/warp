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

  /// SPEC §2 `PIN_ADJUST_MAX_M` — local hint only; the server is authoritative (§13.1).
  static const double pinAdjustMaxM = 30;

  /// SPEC §8 `poi_category` enum, in the server's declared order.
  static const List<String> poiCategories = [
    'landmark',
    'architecture',
    'street_art',
    'nature',
    'viewpoint',
    'other',
  ];

  /// SPEC §6 `ALLOWED_MIME`.
  static const String photoContentType = 'image/jpeg';

  /// SPEC §2 `presence` — check-in fix-gathering (§13.2).
  static const int minFixes = 2;
  static const int maxFixes = 5;
  static const int fixSpanMinS = 8;
  static const int fixWindowMaxS = 25;

  /// SPEC §2 `UPLOAD_MAX_LONG_EDGE_PX` — client-side resize before upload (§13.1).
  static const int uploadMaxLongEdgePx = 2048;

  /// SPEC §2 `UPLOAD_MAX_BYTES` — `resizeForUpload` steps quality down to try to fit this
  /// before the server's own HEAD check (§6) would reject an oversized upload.
  static const int uploadMaxBytes = 1048576;

  /// SPEC §2/§17 `CHECKIN_DEFERRED_MAX_AGE_S` — an outbox item older than this by the time
  /// it's replayed is dropped without a server round trip (the server would
  /// `stale_evidence`-reject it anyway).
  static const int checkinDeferredMaxAgeS = 86400;
}
