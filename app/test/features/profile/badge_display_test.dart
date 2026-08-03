import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/features/profile/badge_display.dart';

void main() {
  group('badgeLabel', () {
    test('maps every SPEC §16 badge key to a human label', () {
      expect(badgeLabel('first_in_region'), 'First in region');
      expect(badgeLabel('poi_milestone_10'), '10 check-ins milestone');
      expect(badgeLabel('poi_milestone_50'), '50 check-ins milestone');
      expect(badgeLabel('poi_milestone_100'), '100 check-ins milestone');
    });

    test('falls back to the raw key for an unrecognized badge', () {
      expect(badgeLabel('some_future_badge'), 'some_future_badge');
    });
  });
}
