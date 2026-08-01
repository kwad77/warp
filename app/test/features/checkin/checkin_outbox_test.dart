import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/features/checkin/checkin_outbox.dart';
import 'package:wanderpost/models/gps_fix.dart';

GpsFix _fix(int seconds) => GpsFix(
      lat: 38.7,
      lng: -9.1,
      accuracyM: 10,
      capturedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
    );

void main() {
  late Directory tempDir;
  late CheckinOutbox outbox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('checkin_outbox_unit_test_');
    outbox = CheckinOutbox(directoryProvider: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('load returns empty before anything is added', () async {
    expect(await outbox.load(), isEmpty);
  });

  test('add then load round-trips a confirm-mode item (no photo)', () async {
    await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 1, 0, 0, 20),
    );

    final items = await outbox.load();
    expect(items, hasLength(1));
    expect(items.single.poiId, 'poi1');
    expect(items.single.mode, 'confirm');
    expect(items.single.fixes, hasLength(2));
    expect(items.single.fixes.first.lat, 38.7);
    expect(items.single.photoPath, isNull);
  });

  test('add with photoBytes writes a file the item then points at', () async {
    final item = await outbox.add(
      poiId: 'poi1',
      mode: 'photo',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 1),
      photoBytes: Uint8List.fromList([1, 2, 3, 4]),
      photoCapturedAt: DateTime.utc(2026, 1, 1),
    );

    expect(item.photoPath, isNotNull);
    final file = File(item.photoPath!);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });

  test('multiple adds persist independently, in order', () async {
    await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 1),
    );
    await outbox.add(
      poiId: 'poi2',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 2),
    );

    final items = await outbox.load();
    expect(items.map((e) => e.poiId), ['poi1', 'poi2']);
  });

  test('remove deletes the manifest entry and its photo file', () async {
    final item = await outbox.add(
      poiId: 'poi1',
      mode: 'photo',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 1),
      photoBytes: Uint8List.fromList([1, 2, 3]),
      photoCapturedAt: DateTime.utc(2026, 1, 1),
    );
    final photoPath = item.photoPath!;

    await outbox.remove(item.id);

    expect(await outbox.load(), isEmpty);
    expect(await File(photoPath).exists(), isFalse);
  });

  test('remove leaves other items untouched', () async {
    final a = await outbox.add(
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 1),
    );
    await outbox.add(
      poiId: 'poi2',
      mode: 'confirm',
      fixes: [_fix(0), _fix(9)],
      attemptedAt: DateTime.utc(2026, 1, 2),
    );

    await outbox.remove(a.id);

    final items = await outbox.load();
    expect(items, hasLength(1));
    expect(items.single.poiId, 'poi2');
  });
}
