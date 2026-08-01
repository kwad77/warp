import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/features/poi/poi_create_outbox.dart';
import 'package:wanderpost/models/gps_fix.dart';
import 'package:wanderpost/models/lat_lng.dart';

final _gpsFix = GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1));
const _location = LatLng(lat: 38.7, lng: -9.1);

void main() {
  late Directory tempDir;
  late PoiCreateOutbox outbox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('poi_create_outbox_unit_test_');
    outbox = PoiCreateOutbox(directoryProvider: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('load returns empty before anything is added', () async {
    expect(await outbox.load(), isEmpty);
  });

  test('add then load round-trips an item with no photo', () async {
    await outbox.add(
      title: 'Torre',
      description: 'A tower',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );

    final items = await outbox.load();
    expect(items, hasLength(1));
    expect(items.single.title, 'Torre');
    expect(items.single.description, 'A tower');
    expect(items.single.category, 'landmark');
    expect(items.single.location, _location);
    expect(items.single.gpsFix, _gpsFix);
    expect(items.single.photoPath, isNull);
  });

  test('add with a null description omits it, not an empty string', () async {
    await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );

    expect((await outbox.load()).single.description, isNull);
  });

  test('add with photoBytes writes a file the item then points at', () async {
    final item = await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
      photoBytes: Uint8List.fromList([1, 2, 3, 4]),
    );

    expect(item.photoPath, isNotNull);
    final file = File(item.photoPath!);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });

  test('remove deletes the manifest entry and its photo file', () async {
    final item = await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
      photoBytes: Uint8List.fromList([1, 2, 3]),
    );
    final photoPath = item.photoPath!;

    await outbox.remove(item.id);

    expect(await outbox.load(), isEmpty);
    expect(await File(photoPath).exists(), isFalse);
  });

  test('remove leaves other items untouched', () async {
    final a = await outbox.add(
      title: 'Torre',
      category: 'landmark',
      location: _location,
      gpsFix: _gpsFix,
    );
    await outbox.add(
      title: 'Miradouro',
      category: 'viewpoint',
      location: _location,
      gpsFix: _gpsFix,
    );

    await outbox.remove(a.id);

    final items = await outbox.load();
    expect(items, hasLength(1));
    expect(items.single.title, 'Miradouro');
  });
}
