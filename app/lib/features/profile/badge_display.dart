import 'package:flutter/material.dart';

/// SPEC §16 — the closed 4-key badge taxonomy (Postgres enum `badge_key`), mirrored here
/// as a switch rather than an open-ended lookup, same pattern as `poiCategoryIcon`.
String badgeLabel(String badgeKey) => switch (badgeKey) {
      'first_in_region' => 'First in region',
      'poi_milestone_10' => '10 check-ins milestone',
      'poi_milestone_50' => '50 check-ins milestone',
      'poi_milestone_100' => '100 check-ins milestone',
      _ => badgeKey,
    };

IconData badgeIcon(String badgeKey) => switch (badgeKey) {
      'first_in_region' => Icons.flag,
      'poi_milestone_10' || 'poi_milestone_50' || 'poi_milestone_100' => Icons.military_tech,
      _ => Icons.emoji_events,
    };
