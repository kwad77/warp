import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Owning this small interface (instead of depending on `FlutterSecureStorage` directly)
/// keeps [TokenStore] unit-testable without a platform channel — flutter_secure_storage's
/// concrete class requires a real device/emulator to run.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  final FlutterSecureStorage _storage;

  FlutterSecureStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
