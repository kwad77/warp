import 'package:flutter/material.dart';

/// SPEC §19 — stands in for a POI's `thumbnailUrl` wherever it's `null` (no approved
/// photo, or an endpoint that doesn't compute it) so a grid/card never renders empty.
IconData poiCategoryIcon(String category) => switch (category) {
      'landmark' => Icons.account_balance,
      'architecture' => Icons.apartment,
      'street_art' => Icons.brush,
      'nature' => Icons.park,
      'viewpoint' => Icons.landscape,
      _ => Icons.place,
    };
