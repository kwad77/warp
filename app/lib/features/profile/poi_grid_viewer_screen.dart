import 'package:flutter/material.dart';

import '../../models/poi_pin.dart';
import '../map/map_screen.dart';
import '../poi/poi_thumbnail.dart';

/// SPEC §19 — tapping a profile-grid cell opens this: a full-screen, swipeable
/// (`PageView`) viewer across that section's items, starting at the tapped one. The
/// "feed-style browsing" this satisfies is over the caller's own grid, not a new
/// endpoint or a public feed of other users' activity.
class PoiGridViewerScreen extends StatefulWidget {
  final List<PoiPin> items;
  final int initialIndex;

  const PoiGridViewerScreen({super.key, required this.items, required this.initialIndex});

  @override
  State<PoiGridViewerScreen> createState() => _PoiGridViewerScreenState();
}

class _PoiGridViewerScreenState extends State<PoiGridViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final poi = widget.items[index];
          return Column(
            children: [
              Expanded(
                child: PoiThumbnail(thumbnailUrl: poi.thumbnailUrl, category: poi.category),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      '${poi.category} · ${poi.checkinCount} check-ins',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => openPoiDetail(context, poi.id),
                      child: const Text('View details'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
