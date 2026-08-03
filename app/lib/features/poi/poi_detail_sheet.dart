import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../models/poi.dart';
import '../checkin/checkin_screen.dart';
import 'report_dialog.dart';

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

  /// SPEC §7 — toggles the caller's own vote on gallery photo [index]. Optimistic:
  /// `voteScore` comes back from the server, `myVote` flips to whatever was just sent.
  Future<void> _vote(int index) async {
    final poi = _poi;
    if (poi == null) return;
    final photo = poi.gallery[index];
    final newMyVote = !photo.myVote;
    try {
      final voteScore = await ref
          .read(wanderpostApiProvider)
          .voteOnPhoto(photo.id, upvote: newMyVote);
      if (!mounted) return;
      setState(() {
        final gallery = [...poi.gallery];
        gallery[index] = photo.copyWith(myVote: newMyVote, voteScore: voteScore);
        _poi = poi.copyWith(gallery: gallery);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
          Row(
            children: [
              Expanded(
                child: Text(poi.title, style: Theme.of(context).textTheme.headlineSmall),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'Report this place',
                onPressed: () =>
                    showReportDialog(context, ref, targetType: 'poi', targetId: poi.id),
              ),
            ],
          ),
          if (poi.description != null) ...[
            const SizedBox(height: 8),
            Text(poi.description!),
          ],
          const SizedBox(height: 8),
          Text('${poi.checkinCount} check-ins · created by ${poi.creatorHandle}'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CheckinScreen(poiId: poi.id)),
            ),
            child: const Text('Check in'),
          ),
          const SizedBox(height: 16),
          if (poi.gallery.isEmpty)
            const Text('No postcards yet — be the first.')
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: poi.gallery.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final photo = poi.gallery[i];
                  return SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            AppConfig.resolveMediaUrl(photo.urlThumb),
                            width: 120,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _vote(i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      photo.myVote ? Icons.thumb_up : Icons.thumb_up_outlined,
                                      size: 16,
                                      color: photo.myVote
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${photo.voteScore}'),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.flag_outlined, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Report this photo',
                              onPressed: () => showReportDialog(
                                context,
                                ref,
                                targetType: 'photo',
                                targetId: photo.id,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
