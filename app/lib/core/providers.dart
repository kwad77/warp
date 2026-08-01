import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../features/map/map_controller.dart';
import '../features/map/map_view_state.dart';
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
