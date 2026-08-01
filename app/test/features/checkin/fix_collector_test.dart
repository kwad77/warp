import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/features/checkin/fix_collector.dart';
import 'package:wanderpost/models/gps_fix.dart';

GpsFix _fixAt(int seconds) => GpsFix(
      lat: 1,
      lng: 2,
      accuracyM: 10,
      capturedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
    );

void main() {
  test('stops once minFixes reached and span >= minSpan', () async {
    final fixes = collectFixes(
      Stream.fromIterable([_fixAt(0), _fixAt(3), _fixAt(9), _fixAt(20)]),
      minFixes: 2,
      maxFixes: 5,
      minSpan: const Duration(seconds: 8),
      maxWindow: const Duration(seconds: 25),
    );

    expect(await fixes, [_fixAt(0), _fixAt(3), _fixAt(9)]);
  });

  test('stops at maxFixes even if minSpan not yet reached', () async {
    final fixes = collectFixes(
      Stream.fromIterable([_fixAt(0), _fixAt(1), _fixAt(2), _fixAt(3), _fixAt(4), _fixAt(5)]),
      minFixes: 2,
      maxFixes: 3,
      minSpan: const Duration(seconds: 8),
      maxWindow: const Duration(seconds: 25),
    );

    expect(await fixes, [_fixAt(0), _fixAt(1), _fixAt(2)]);
  });

  test('stops at maxWindow even below minFixes', () async {
    final fixes = collectFixes(
      Stream.fromIterable([_fixAt(0), _fixAt(30)]),
      minFixes: 2,
      maxFixes: 5,
      minSpan: const Duration(seconds: 8),
      maxWindow: const Duration(seconds: 25),
    );

    expect(await fixes, [_fixAt(0), _fixAt(30)]);
  });

  test('stream ending early returns whatever was collected', () async {
    final fixes = collectFixes(
      Stream.fromIterable([_fixAt(0)]),
      minFixes: 2,
      maxFixes: 5,
      minSpan: const Duration(seconds: 8),
      maxWindow: const Duration(seconds: 25),
    );

    expect(await fixes, [_fixAt(0)]);
  });
}
