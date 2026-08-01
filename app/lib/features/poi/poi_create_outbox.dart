import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../models/gps_fix.dart';
import '../../models/lat_lng.dart';
import '../../models/queued_poi_creation.dart';

/// SPEC §18 — durable (survives app restart) local queue for POI creations attempted
/// with no connectivity. Structurally the same as `checkin/CheckinOutbox` (SPEC §17) —
/// kept as a separate, small implementation rather than a shared abstraction with only
/// two call sites so far (see SPEC §18's "deferred, flagged").
///
/// [directoryProvider] defaults to the real app documents directory; tests inject a temp
/// directory instead so this class's actual file-I/O logic runs for real.
class PoiCreateOutbox {
  final Future<Directory> Function() directoryProvider;

  PoiCreateOutbox({Future<Directory> Function()? directoryProvider})
      : directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  Future<Directory> _dir() async {
    final docs = await directoryProvider();
    final dir = Directory('${docs.path}/poi_create_outbox');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _manifestFile() async {
    final dir = await _dir();
    return File('${dir.path}/manifest.json');
  }

  Future<List<QueuedPoiCreation>> load() async {
    final file = await _manifestFile();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => QueuedPoiCreation.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> _save(List<QueuedPoiCreation> items) async {
    final file = await _manifestFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  /// [photoBytes], if given, is already face-gated and resized (SPEC §6/§13.1) — the same
  /// processing the live POI-creation path runs before it ever touches the network.
  Future<QueuedPoiCreation> add({
    required String title,
    String? description,
    required String category,
    required LatLng location,
    required GpsFix gpsFix,
    Uint8List? photoBytes,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    String? photoPath;
    if (photoBytes != null) {
      final dir = await _dir();
      photoPath = '${dir.path}/$id.jpg';
      await File(photoPath).writeAsBytes(photoBytes);
    }
    final item = QueuedPoiCreation(
      id: id,
      title: title,
      description: description,
      category: category,
      location: location,
      gpsFix: gpsFix,
      photoPath: photoPath,
    );
    final items = await load();
    items.add(item);
    await _save(items);
    return item;
  }

  Future<void> remove(String id) async {
    final items = await load();
    QueuedPoiCreation? removed;
    items.removeWhere((e) {
      final match = e.id == id;
      if (match) removed = e;
      return match;
    });
    await _save(items);
    final photoPath = removed?.photoPath;
    if (photoPath != null) {
      final file = File(photoPath);
      if (await file.exists()) await file.delete();
    }
  }
}
