import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/providers.dart';
import '../../models/poi.dart';

/// SPEC §12 — fetches `GET /pois/:id` on open; postcard gallery, check-in count,
/// creator credit. Check-in itself is M1 step 4, not built here.
class PoiDetailSheet extends ConsumerStatefulWidget {
  final String poiId;

  const PoiDetailSheet({super.key, required this.poiId});

  @override
  ConsumerState<PoiDetailSheet> createState() => _PoiDetailSheetState();
}

class _PoiDetailSheetState extends ConsumerState<PoiDetailSheet> {
  Poi? _poi;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final poi = await ref.read(wanderpostApiProvider).poiDetail(widget.poiId);
      if (!mounted) return;
      setState(() {
        _poi = poi;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SizedBox(height: 200, child: Center(child: Text(_error!)));
    }
    final poi = _poi!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Text(poi.title, style: Theme.of(context).textTheme.headlineSmall),
          if (poi.description != null) ...[
            const SizedBox(height: 8),
            Text(poi.description!),
          ],
          const SizedBox(height: 8),
          Text('${poi.checkinCount} check-ins · created by ${poi.creatorHandle}'),
          const SizedBox(height: 16),
          if (poi.gallery.isEmpty)
            const Text('No postcards yet — be the first.')
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: poi.gallery.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(poi.gallery[i].urlThumb, width: 120, fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
