import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../features/checkin/checkin_controller.dart';
import '../features/checkin/checkin_state.dart';
import '../features/checkin/checkin_outbox.dart';
import '../features/checkin/checkin_outbox_controller.dart';
import '../features/checkin/checkin_outbox_state.dart';
import '../features/checkin/integrity_token_provider.dart';
import '../features/coverage/personal_map_controller.dart';
import '../features/coverage/personal_map_state.dart';
import '../features/map/map_controller.dart';
import '../features/map/map_view_state.dart';
import '../features/poi/face_gate.dart';
import '../features/poi/location_source.dart';
import '../features/poi/photo_uploader.dart';
import '../features/poi/poi_create_controller.dart';
import '../features/poi/poi_create_state.dart';
import '../features/profile/profile_controller.dart';
import '../features/profile/profile_state.dart';
import 'api_client.dart';
import 'constants.dart';
import 'device_store.dart';
import 'token_store.dart';
import 'wanderpost_api.dart';

// Explicit LHS types on this mutually-referencing group break a top-level type-inference
// cycle Dart's analyzer otherwise reports (apiClient -> authController -> wanderpostApi ->
// apiClient) even though the actual reference (inside onSessionExpired) only ever runs
// lazily, well after every provider exists — there is no real runtime cycle.
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStore: tokenStore,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});

final Provider<WanderpostApi> wanderpostApiProvider = Provider<WanderpostApi>((ref) {
  return WanderpostApi(ref.watch(apiClientProvider));
});

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    api: ref.watch(wanderpostApiProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  )..restore();
});

final StateNotifierProvider<MapController, MapViewState> mapControllerProvider =
    StateNotifierProvider<MapController, MapViewState>((ref) {
  return MapController(ref.watch(wanderpostApiProvider));
});

// SPEC §13.1 — POI creation. Real (device-backed) implementations; tests inject fakes
// directly into PoiCreateController rather than overriding these providers.
final Provider<FaceGate> faceGateProvider = Provider<FaceGate>((ref) => MlKitFaceGate());
final Provider<PhotoUploader> photoUploaderProvider = Provider<PhotoUploader>((ref) => HttpPhotoUploader());
final Provider<LocationSource> locationSourceProvider =
    Provider<LocationSource>((ref) => GeolocatorLocationSource());

// autoDispose: PoiCreateScreen is the only watcher, and a fresh controller (not stale
// `created`/`dedupe` state from a prior visit) MUST greet the next time it's opened.
final AutoDisposeStateNotifierProvider<PoiCreateController, PoiCreateState>
    poiCreateControllerProvider =
    StateNotifierProvider.autoDispose<PoiCreateController, PoiCreateState>((ref) {
  return PoiCreateController(
    api: ref.watch(wanderpostApiProvider),
    faceGate: ref.watch(faceGateProvider),
    uploader: ref.watch(photoUploaderProvider),
  );
});

// SPEC §13.2 — check-in. DeviceStore mirrors TokenStore; DevIntegrityTokenProvider is the
// only IntegrityTokenProvider implementation in M1 (real platform attestation is a scoped-
// out named seam, §5.2). autoDispose for the same reason as poiCreateControllerProvider.
final Provider<DeviceStore> deviceStoreProvider = Provider<DeviceStore>((ref) => DeviceStore());
final Provider<IntegrityTokenProvider> checkinIntegrityTokenProvider =
    Provider<IntegrityTokenProvider>((ref) => DevIntegrityTokenProvider());

// SPEC §17 — offline check-in outbox. Not autoDispose: RootScreen loads/replays it once
// at app start and its "pending sync" state should survive navigating away and back.
final Provider<CheckinOutbox> checkinOutboxProvider = Provider<CheckinOutbox>((ref) => CheckinOutbox());

final StateNotifierProvider<CheckinOutboxController, CheckinOutboxState>
    checkinOutboxControllerProvider =
    StateNotifierProvider<CheckinOutboxController, CheckinOutboxState>((ref) {
  return CheckinOutboxController(
    api: ref.watch(wanderpostApiProvider),
    outbox: ref.watch(checkinOutboxProvider),
    integrityTokenProvider: ref.watch(checkinIntegrityTokenProvider),
    uploader: ref.watch(photoUploaderProvider),
    deviceStore: ref.watch(deviceStoreProvider),
  );
});

final AutoDisposeStateNotifierProvider<CheckinController, CheckinState> checkinControllerProvider =
    StateNotifierProvider.autoDispose<CheckinController, CheckinState>((ref) {
  return CheckinController(
    api: ref.watch(wanderpostApiProvider),
    locationSource: ref.watch(locationSourceProvider),
    integrityTokenProvider: ref.watch(checkinIntegrityTokenProvider),
    faceGate: ref.watch(faceGateProvider),
    uploader: ref.watch(photoUploaderProvider),
    outbox: ref.watch(checkinOutboxProvider),
  );
});

// SPEC §14 — profile screen.
final StateNotifierProvider<ProfileController, ProfileState> profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.watch(wanderpostApiProvider));
});

// SPEC §15 — personal coverage map. autoDispose: PersonalMapScreen is pushed on demand
// (not a persistent tab), and a fresh visit should re-fetch rather than reuse a stale
// cached `GET /me/map` from a previous visit.
final AutoDisposeStateNotifierProvider<PersonalMapController, PersonalMapState>
    personalMapControllerProvider =
    StateNotifierProvider.autoDispose<PersonalMapController, PersonalMapState>((ref) {
  return PersonalMapController(ref.watch(wanderpostApiProvider));
});
