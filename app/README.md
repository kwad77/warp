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

No live device or emulator is available in the sandbox this app was built in — `flutter
analyze` and `flutter test` were the verification gate; nobody has visually run this UI
yet. Treat the first real device run as still owed, not a formality.

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
