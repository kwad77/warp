import 'dart:io';

import '../../core/device_store.dart';
import '../../core/wanderpost_api.dart';

/// SPEC §13.2 — lazy, once, cached: the first check-in of the install registers the
/// device; every one after reuses the cached id.
Future<String> ensureDeviceId(WanderpostApi api, DeviceStore store) async {
  final cached = await store.readDeviceId();
  if (cached != null) return cached;
  final deviceId = await api.registerDevice(platform: Platform.isIOS ? 'ios' : 'android');
  await store.saveDeviceId(deviceId);
  return deviceId;
}
