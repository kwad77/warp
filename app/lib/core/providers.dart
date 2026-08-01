import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../features/map/map_controller.dart';
import '../features/map/map_view_state.dart';
import '../features/poi/face_gate.dart';
import '../features/poi/location_source.dart';
import '../features/poi/photo_uploader.dart';
import '../features/poi/poi_create_controller.dart';
import '../features/poi/poi_create_state.dart';
import 'api_client.dart';
import 'constants.dart';
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
