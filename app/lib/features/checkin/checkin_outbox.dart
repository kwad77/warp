import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../models/gps_fix.dart';
import '../../models/queued_checkin.dart';

/// SPEC §17 — durable (survives app restart) local queue for check-ins attempted with no
/// connectivity: a JSON manifest plus any already-processed photo bytes, both in the
/// app's own documents directory. Nothing here talks to the network; replay is
/// `CheckinOutboxController`'s job.
///
/// [directoryProvider] defaults to the real app documents directory (`path_provider`,
/// which needs a real device/platform channel); tests inject a temp directory instead so
/// this class's actual file-I/O logic runs for real rather than being faked away.
class CheckinOutbox {
  final Future<Directory> Function() directoryProvider;

  CheckinOutbox({Future<Directory> Function()? directoryProvider})
      : directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  Future<Directory> _dir() async {
    final docs = await directoryProvider();
    final dir = Directory('${docs.path}/checkin_outbox');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _manifestFile() async {
    final dir = await _dir();
    return File('${dir.path}/manifest.json');
  }

  Future<List<QueuedCheckin>> load() async {
    final file = await _manifestFile();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => QueuedCheckin.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> _save(List<QueuedCheckin> items) async {
    final file = await _manifestFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  /// [photoBytes], if given, is already resized/re-encoded for upload (SPEC §6/§13.1) —
  /// the same processing the live check-in path runs before it ever touches the network.
  Future<QueuedCheckin> add({
    required String poiId,
    required String mode,
    required List<GpsFix> fixes,
    required DateTime attemptedAt,
    Uint8List? photoBytes,
    DateTime? photoCapturedAt,
  }) async {
    final id = '${attemptedAt.microsecondsSinceEpoch}-$poiId';
    String? photoPath;
    if (photoBytes != null) {
      final dir = await _dir();
      photoPath = '${dir.path}/$id.jpg';
      await File(photoPath).writeAsBytes(photoBytes);
    }
    final item = QueuedCheckin(
      id: id,
      poiId: poiId,
      mode: mode,
      fixes: fixes,
      attemptedAt: attemptedAt,
      photoPath: photoPath,
      photoCapturedAt: photoCapturedAt,
    );
    final items = await load();
    items.add(item);
    await _save(items);
    return item;
  }

  Future<void> remove(String id) async {
    final items = await load();
    QueuedCheckin? removed;
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
