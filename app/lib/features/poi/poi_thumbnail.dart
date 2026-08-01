import 'package:flutter/material.dart';

import 'poi_category_icon.dart';

/// SPEC §19 — a `thumbnailUrl` image, or a category-icon placeholder tile when it's
/// `null`. Shared by the profile grid, the grid viewer, and the discovery feed's cards.
class PoiThumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  final String category;
  final BoxFit fit;

  const PoiThumbnail({
    super.key,
    required this.thumbnailUrl,
    required this.category,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = thumbnailUrl;
    if (url == null) {
      return ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(poiCategoryIcon(category), color: Colors.grey.shade500, size: 32),
        ),
      );
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(poiCategoryIcon(category), color: Colors.grey.shade500, size: 32),
        ),
      ),
    );
  }
}
