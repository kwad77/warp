import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/poi_pin.dart';
import '../map/map_screen.dart';
import '../poi/poi_thumbnail.dart';

/// SPEC §19 — "places around me" (nearby POIs) and "places I want to visit" (the
/// caller's saved list), as a vertical scroll of cards. No public feed of other users'
/// activity — see the module doc on `FeedState`.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(feedControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    final savedIds = state.saved.map((p) => p.id).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedControllerProvider.notifier).load(),
        child: state.loading && state.nearby.isEmpty && state.saved.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.errorMessage != null) ...[
                    Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                  ],
                  Text('Places around me', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (state.nearby.isEmpty)
                    const Text('No places found nearby yet.')
                  else
                    for (final poi in state.nearby)
                      _FeedCard(poi: poi, saved: savedIds.contains(poi.id)),
                  const SizedBox(height: 24),
                  Text('Places I want to visit', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (state.saved.isEmpty)
                    const Text("Tap the bookmark on a place to save it here.")
                  else
                    for (final poi in state.saved) _FeedCard(poi: poi, saved: true),
                ],
              ),
      ),
    );
  }
}

class _FeedCard extends ConsumerWidget {
  final PoiPin poi;
  final bool saved;

  const _FeedCard({required this.poi, required this.saved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => openPoiDetail(context, poi.id),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: PoiThumbnail(thumbnailUrl: poi.thumbnailUrl, category: poi.category),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(poi.title, style: Theme.of(context).textTheme.titleSmall),
                    Text('${poi.category} · ${poi.checkinCount} check-ins'),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => ref.read(feedControllerProvider.notifier).toggleSaved(poi.id),
            ),
          ],
        ),
      ),
    );
  }
}
