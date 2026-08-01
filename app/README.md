# Wanderpost app

Flutter client. Everything here implements [SPEC.md §12](../SPEC.md) — read it before
changing behavior. This slice (M1 step 3) covers map browsing, POI detail, and
email-code auth. Check-in, camera capture, and on-device face detection are M1 step 4.

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

All three must be clean/green. No live device is required for any of them.

## Layout

```
lib/core/       API client (auth interceptor, refresh-on-401), token storage
                (Keychain/Keystore via a small SecureStore interface so it's testable),
                app-wide constants, Riverpod provider wiring
lib/models/     Hand-written fromMap (not fromJson — see note below) + freezed
lib/features/   auth/ (email-code flow), map/ (MapLibre + server-driven clustering),
                poi/ (detail sheet)
test/           Mirrors lib/; test/helpers/fake_adapter.dart is a small in-repo Dio
                HttpClientAdapter fake (no mock-http package needed) used across the
                API client, map controller, and auth controller tests.
```

**Why `fromMap`, not `fromJson`:** naming a factory `fromJson` inside a `@freezed` class
triggers freezed's json_serializable-integration codegen path regardless of the factory's
actual body, which fails to compile without a `.g.dart` part. `fromMap` is the same thing,
named to dodge that codegen trigger — deliberate, not an oversight.
