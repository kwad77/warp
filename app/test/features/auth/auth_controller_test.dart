import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/auth/auth_controller.dart';
import 'package:wanderpost/features/auth/auth_state.dart';
import 'package:wanderpost/models/user.dart';

import '../../helpers/fake_adapter.dart';

class _InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

({WanderpostApi api, TokenStore tokenStore, FakeAdapter adapter}) _build() {
  final adapter = FakeAdapter();
  final tokenStore = TokenStore(storage: _InMemorySecureStore());
  final api = WanderpostApi(
    ApiClient(baseUrl: 'http://test', tokenStore: tokenStore, dio: buildFakeDio(adapter)),
  );
  return (api: api, tokenStore: tokenStore, adapter: adapter);
}

void main() {
  test('starts loggedOut', () {
    final built = _build();
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);
    expect(controller.state, const AuthState.loggedOut());
  });

  test('requestCode success transitions to codeSent(email)', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/auth/email/request', 200, {'ok': true});
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);

    await controller.requestCode('a@example.com');

    expect(controller.state, const AuthState.codeSent('a@example.com'));
  });

  test('requestCode failure transitions to error(message)', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/auth/email/request', 429, {
      'error': {'code': 'rate/limited', 'message': 'Too many code requests'},
    });
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);

    await controller.requestCode('a@example.com');

    expect(controller.state, const AuthState.error('Too many code requests'));
  });

  test('verifyCode success persists tokens+user and transitions to loggedIn', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/auth/email/verify', 200, {
      'accessToken': 'acc-1',
      'refreshToken': 'ref-1',
      'user': {'id': 'u1', 'handle': 'explorer_x', 'createdAt': '2026-01-01T00:00:00Z'},
    });
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);

    await controller.verifyCode('a@example.com', '123456');

    expect(
      controller.state,
      const AuthState.loggedIn(User(id: 'u1', handle: 'explorer_x', createdAt: '2026-01-01T00:00:00Z')),
    );
    expect(await built.tokenStore.readAccessToken(), 'acc-1');
    expect(await built.tokenStore.readUser(), isNotNull);
  });

  test('verifyCode failure (wrong code) transitions to error, no tokens saved', () async {
    final built = _build();
    built.adapter.onJson('POST', '/v1/auth/email/verify', 401, {
      'error': {'code': 'auth/invalid', 'message': 'Invalid or expired code'},
    });
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);

    await controller.verifyCode('a@example.com', '000000');

    expect(controller.state, const AuthState.error('Invalid or expired code'));
    expect(await built.tokenStore.readAccessToken(), isNull);
  });

  test('restore() with a cached token+user goes straight to loggedIn, no network call', () async {
    final built = _build();
    const user = User(id: 'u1', handle: 'explorer_x', createdAt: '2026-01-01T00:00:00Z');
    await built.tokenStore.save(accessToken: 'acc-1', refreshToken: 'ref-1', user: user);
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);

    await controller.restore();

    expect(controller.state, const AuthState.loggedIn(user));
    expect(built.adapter.requests, isEmpty); // no eager /me call, per SPEC §12
  });

  test('restore() with nothing cached stays loggedOut', () async {
    final built = _build();
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);

    await controller.restore();

    expect(controller.state, const AuthState.loggedOut());
  });

  test('sessionExpired() forces loggedOut regardless of prior state', () async {
    final built = _build();
    const user = User(id: 'u1', handle: 'explorer_x', createdAt: '2026-01-01T00:00:00Z');
    await built.tokenStore.save(accessToken: 'acc-1', refreshToken: 'ref-1', user: user);
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);
    await controller.restore();
    expect(controller.state, isA<AuthState>());

    controller.sessionExpired();

    expect(controller.state, const AuthState.loggedOut());
  });

  test('signOut clears the token store and returns to loggedOut', () async {
    final built = _build();
    const user = User(id: 'u1', handle: 'explorer_x', createdAt: '2026-01-01T00:00:00Z');
    await built.tokenStore.save(accessToken: 'acc-1', refreshToken: 'ref-1', user: user);
    final controller = AuthController(api: built.api, tokenStore: built.tokenStore);
    await controller.restore();

    await controller.signOut();

    expect(controller.state, const AuthState.loggedOut());
    expect(await built.tokenStore.readAccessToken(), isNull);
  });
}
