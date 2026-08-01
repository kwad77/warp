import 'secure_store.dart';

/// Caches the device's `deviceId` (SPEC §7 `POST /devices`) — Keychain/Keystore-backed,
/// same pattern and rationale as `TokenStore` (SPEC §13.2).
class DeviceStore {
  final SecureStore _storage;

  DeviceStore({SecureStore? storage}) : _storage = storage ?? FlutterSecureStore();

  static const _deviceIdKey = 'wanderpost.device_id';

  Future<String?> readDeviceId() => _storage.read(_deviceIdKey);

  Future<void> saveDeviceId(String deviceId) => _storage.write(_deviceIdKey, deviceId);
}
