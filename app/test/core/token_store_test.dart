import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/models/user.dart';

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

void main() {
  late _InMemorySecureStore backing;
  late TokenStore store;

  setUp(() {
    backing = _InMemorySecureStore();
    store = TokenStore(storage: backing);
  });

  test('save then read round-trips access, refresh, and cached user', () async {
    const user = User(id: 'u1', handle: 'explorer_abc', createdAt: '2026-01-01T00:00:00Z');
    await store.save(accessToken: 'access-1', refreshToken: 'refresh-1', user: user);

    expect(await store.readAccessToken(), 'access-1');
    expect(await store.readRefreshToken(), 'refresh-1');
    expect(await store.readUser(), user);
  });

  test('save without a user leaves a previously-cached user intact', () async {
    const user = User(id: 'u1', handle: 'explorer_abc', createdAt: '2026-01-01T00:00:00Z');
    await store.save(accessToken: 'a1', refreshToken: 'r1', user: user);
    await store.save(accessToken: 'a2', refreshToken: 'r2');

    expect(await store.readAccessToken(), 'a2');
    expect(await store.readUser(), user);
  });

  test('clear removes tokens and the cached user', () async {
    const user = User(id: 'u1', handle: 'explorer_abc', createdAt: '2026-01-01T00:00:00Z');
    await store.save(accessToken: 'a1', refreshToken: 'r1', user: user);
    await store.clear();

    expect(await store.readAccessToken(), isNull);
    expect(await store.readRefreshToken(), isNull);
    expect(await store.readUser(), isNull);
  });

  test('reads are null before anything is saved', () async {
    expect(await store.readAccessToken(), isNull);
    expect(await store.readUser(), isNull);
  });
}
