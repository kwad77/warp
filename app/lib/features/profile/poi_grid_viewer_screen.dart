import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/share_image.dart';
import '../../models/poi_pin.dart';
import '../map/map_screen.dart';
import '../poi/poi_thumbnail.dart';

/// SPEC §19 — tapping a profile-grid cell opens this: a full-screen, swipeable
/// (`PageView`) viewer across that section's items, starting at the tapped one. The
/// "feed-style browsing" this satisfies is over the caller's own grid, not a new
/// endpoint or a public feed of other users' activity. The app-bar share action shares
/// whichever item the `PageView` currently shows.
class PoiGridViewerScreen extends StatefulWidget {
  final List<PoiPin> items;
  final int initialIndex;

  const PoiGridViewerScreen({super.key, required this.items, required this.initialIndex});

  @override
  State<PoiGridViewerScreen> createState() => _PoiGridViewerScreenState();
}

class _PoiGridViewerScreenState extends State<PoiGridViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;
  bool _sharing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final poi = widget.items[_currentIndex];
    final url = poi.thumbnailUrl;
    if (url == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      final response = await Dio().get<List<int>>(
        AppConfig.resolveMediaUrl(url),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) return;
      await shareImageBytes(bytes, filename: '${poi.id}.jpg', text: poi.title);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShare = widget.items[_currentIndex].thumbnailUrl != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (canShare)
            IconButton(
              icon: _sharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share),
              onPressed: _sharing ? null : _share,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentIndex = index),
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
