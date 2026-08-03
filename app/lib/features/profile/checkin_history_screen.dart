import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/checkin_list_item.dart';
import '../map/map_screen.dart';
import '../poi/poi_category_icon.dart';

/// SPEC §7 — the caller's own check-in history (`GET /me/checkins`), every status shown
/// so a `pending`/`rejected` check-in is at least visible, even though nothing yet
/// resolves `pending` (SPEC §5.7, flagged in docs/MILESTONES.md).
class CheckinHistoryScreen extends ConsumerStatefulWidget {
  const CheckinHistoryScreen({super.key});

  @override
  ConsumerState<CheckinHistoryScreen> createState() => _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends ConsumerState<CheckinHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(checkinHistoryControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinHistoryControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in history')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.read(checkinHistoryControllerProvider.notifier).load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.items.isEmpty
                  ? const Center(child: Text('No check-ins yet.'))
                  : ListView.builder(
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          if (state.nextCursor == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: state.loadingMore
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: () => ref
                                          .read(checkinHistoryControllerProvider.notifier)
                                          .loadMore(),
                                      child: const Text('Load more'),
                                    ),
                            ),
                          );
                        }
                        return _CheckinTile(item: state.items[index]);
                      },
                    ),
    );
  }
}

class _CheckinTile extends StatelessWidget {
  final CheckinListItem item;

  const _CheckinTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(poiCategoryIcon(item.poiCategory)),
      title: Text(item.poiTitle),
      subtitle: Text(_statusLabel(item.status)),
      trailing: Icon(_statusIcon(item.status), color: _statusColor(item.status)),
      onTap: () => openPoiDetail(context, item.poiId),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'verified' => 'Verified',
        'pending' => 'Pending review',
        'rejected' => 'Not verified',
        _ => status,
      };

  IconData _statusIcon(String status) => switch (status) {
        'verified' => Icons.check_circle,
        'pending' => Icons.hourglass_top,
        'rejected' => Icons.error_outline,
        _ => Icons.help_outline,
      };

  Color _statusColor(String status) => switch (status) {
        'verified' => Colors.green,
        'pending' => Colors.orange,
        'rejected' => Colors.red,
        _ => Colors.grey,
      };
}
