import 'dart:convert';

import '../models/user.dart';
import 'secure_store.dart';

/// Keychain/Keystore-backed token persistence (SPEC §12 — SharedPreferences would put
/// JWTs in plaintext). Also caches the logged-in [User] record so app launch can restore
/// `AuthState.loggedIn` without an eager `/me` call.
class TokenStore {
  final SecureStore _storage;

  TokenStore({SecureStore? storage}) : _storage = storage ?? FlutterSecureStore();

  static const _accessKey = 'wanderpost.access_token';
  static const _refreshKey = 'wanderpost.refresh_token';
  static const _userKey = 'wanderpost.user';

  Future<String?> readAccessToken() => _storage.read(_accessKey);
  Future<String?> readRefreshToken() => _storage.read(_refreshKey);

  Future<User?> readUser() async {
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    return User.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    User? user,
  }) async {
    await _storage.write(_accessKey, accessToken);
    await _storage.write(_refreshKey, refreshToken);
    if (user != null) {
      await _storage.write(
        _userKey,
        jsonEncode({'id': user.id, 'handle': user.handle, 'createdAt': user.createdAt}),
      );
    }
  }

  Future<void> clear() async {
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
    await _storage.delete(_userKey);
  }
}
