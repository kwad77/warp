import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/token_store.dart';
import '../../core/wanderpost_api.dart';
import 'auth_state.dart';

/// SPEC §12 — email-code auth flow state machine.
class AuthController extends StateNotifier<AuthState> {
  final WanderpostApi api;
  final TokenStore tokenStore;

  AuthController({required this.api, required this.tokenStore}) : super(const AuthState.loggedOut());

  /// Call once at app launch: a cached token + user record restores `loggedIn` without
  /// an eager `/me` call (SPEC §12).
  Future<void> restore() async {
    final accessToken = await tokenStore.readAccessToken();
    final user = await tokenStore.readUser();
    if (accessToken != null && user != null) {
      state = AuthState.loggedIn(user);
    }
  }

  Future<void> requestCode(String email) async {
    try {
      await api.requestEmailCode(email);
      state = AuthState.codeSent(email);
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
    }
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      final result = await api.verifyEmailCode(email, code);
      await tokenStore.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );
      state = AuthState.loggedIn(result.user);
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
    }
  }

  /// Invoked by [ApiClient.onSessionExpired] when a refresh attempt fails outright.
  void sessionExpired() {
    state = const AuthState.loggedOut();
  }

  Future<void> signOut() async {
    await tokenStore.clear();
    state = const AuthState.loggedOut();
  }
}
