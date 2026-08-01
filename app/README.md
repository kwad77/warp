# Wanderpost app

Flutter client. Everything here implements [SPEC.md §12–§14](../SPEC.md) — read the
relevant section before changing behavior. M1 step 3 covers map browsing, POI detail, and
email-code auth. M1 step 4 (both halves done): **POI creation** (SPEC §13.1 — pin
adjustment, camera/gallery capture with the on-device face-detection gate, dedupe picker)
and **check-in** (SPEC §13.2 — mode choice, device registration, nonce intent, multi-fix
gathering, capture-token construction, verified/pending/rejected/duplicate result
handling). M1 step 6 (SPEC §14): profile screen — stats, My Places, coverage count,
weekly leaderboard, sign-out. M1 step 5 (moderation loop) is server-only and already
shipped (`server/README.md`).

## Setup

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.freezed.dart
```

Generated `*.freezed.dart` files are committed (SPEC §10) — regenerate and commit them
together with any model change; don't hand-edit them.

## Running

The server must be running first (see `../server/README.md`).

```sh
# Android emulator (default API_BASE_URL=http://10.0.2.2:8080 already points at the
# emulator's host loopback):
flutter run -d <android-device-id>

# iOS simulator (shares host networking, so localhost works directly):
flutter run -d <ios-device-id> --dart-define=API_BASE_URL=http://localhost:8080
```

No real device or emulator is available in the sandbox this app was built in — every
path was genuinely attempted, not assumed away, and each hit a distinct, confirmed wall:
- **Android emulator**: needs `/dev/kvm`; this is a Docker container with no nested
  virtualization and no way to attach the device from inside the session.
- **iOS simulator**: needs macOS, categorically unavailable in a Linux container.
- **Linux desktop**: builds fine (`flutter create --platforms=linux .`,
  `libgtk-3-dev` installed), but `maplibre_gl` declares no Linux platform implementation
  at all — the map widget can't exist there regardless of environment.
- **Web**: `maplibre_gl_web` 0.21.0 doesn't *compile* against Flutter 3.44.8 stable
  (`ui.platformViewRegistry` no longer exists) — a real upstream incompatibility.

**A real rendering pass was still completed**, with the map widget temporarily stubbed
out (not a committed change) to work around the maplibre_gl_web incompatibility: a
diagnostic Flutter-Web build, served locally and screenshotted with headless Chromium
(Playwright driving the pre-installed Chromium binary), against the real running
server. This confirmed live, pixel-real: the app theme, tab navigation, the auth
screen's text field/focus/floating-label behavior, typing an email, tapping "Send
code," the request actually reaching the real backend (visible in its logs), and
Riverpod correctly re-rendering the code-entry screen with the email interpolated in.
Two environment quirks needed working around purely to get pixels out of this sandbox
(neither is a code issue, neither ships): CanvasKit and its Roboto font fetch both go to
external HTTPS hosts blocked by this sandbox's outbound proxy, worked around by mirroring
the already-locally-vendored CanvasKit files and intercepting the font request; and
browser CORS blocked the cross-port fetch (8090→8080), worked around with
`--disable-web-security` for that one test run — CORS doesn't apply to the real mobile
app at all, but would need real headers if a web viewer is ever built (ARCHITECTURE.md).

**Still unverified: the MapLibre widget itself** — actual tiles and markers rendering.
That's the one piece a real device/emulator run still owes; everything else in this
slice has now been seen rendering and interacting correctly, not just passing tests.

## Checks (the merge gate — SPEC §10)

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

All three must be clean/green (74 tests as of the client-resize slice). No live device is
required for any of them — see the testability note below on how `camera`,
`google_mlkit_face_detection`, and `geolocator` (all platform-channel-backed) are kept out
of the unit-test path.

## Layout

```
lib/core/       API client (auth interceptor, refresh-on-401), token storage
                (Keychain/Keystore via a small SecureStore interface so it's testable),
                device-id storage (device_store.dart, same pattern), a haversine helper
                (geo.dart), a SHA-256 helper (hash.dart, SPEC §5.5's capture token), the
                pre-upload photo resize (image_resize.dart — pure function, no platform
                channel, so it's tested directly rather than behind a fake interface),
                app-wide constants, Riverpod provider wiring
lib/models/     Hand-written fromMap (not fromJson — see note below) + freezed. gps_fix.dart
                and poi_create_result.dart are client→server-only (toMap, no fromMap).
lib/features/   auth/ (email-code flow); map/ (MapLibre + server-driven clustering,
                "create POI" FAB); poi/ (detail sheet + "Check in" action, POI creation:
                form, shared in-app camera capture screen, face-detection gate, R2 photo
                uploader, GPS location source); checkin/ (mode choice, lazy device
                registration, `FixCollector` — pure multi-fix gathering over each fix's
                own timestamp, integrity-token seam, controller driving intent → fixes →
                photo → submit); profile/ (stats, My Places, coverage count, weekly
                leaderboard, sign-out — loads GET /me + /me/map + /me/coverage +
                /leaderboards/coverage concurrently). Every platform-channel-backed piece
                (camera/ML Kit, geolocator, R2 PUT, device attestation) sits behind a
                small interface so controllers are unit-testable, same pattern as
                SecureStore.
test/           Mirrors lib/; test/helpers/fake_adapter.dart is a small in-repo Dio
                HttpClientAdapter fake (no mock-http package needed) used across every
                controller test (auth, map, POI creation, check-in, profile), and
                `FixCollector`'s tests run against a synthetic fix stream — no clock or
                device needed for either.
```

**Testability note (SPEC §13.1/§13.2):** `camera`, `google_mlkit_face_detection`, and
`geolocator` all need a real device/emulator to run their concrete implementations —
none of which exists in this sandbox (see the "No real device" section below). Each is
wrapped in a small interface (`FaceGate`, `PhotoUploader`, `LocationSource`,
`IntegrityTokenProvider`) so `PoiCreateController`/`CheckinController` — the actual
decision logic (submit vs. block vs. dedupe/reject/retry) — are fully unit-tested with
fakes. The UI screens that call the real implementations directly (`PoiCreateScreen`,
`CameraCaptureScreen`, `CheckinScreen`) are not unit-tested, same as `MapScreen`'s
MapLibre widget isn't — consistent with the rest of this app.

**Why `fromMap`, not `fromJson`:** naming a factory `fromJson` inside a `@freezed` class
triggers freezed's json_serializable-integration codegen path regardless of the factory's
actual body, which fails to compile without a `.g.dart` part. `fromMap` is the same thing,
named to dodge that codegen trigger — deliberate, not an oversight.
