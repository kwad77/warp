import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/providers.dart';
import '../../core/share_image.dart';
import '../../models/leaderboard_entry.dart';
import '../../models/leaderboard_result.dart';
import '../../models/me_map.dart';
import '../../models/me_stats.dart';
import '../../models/poi_pin.dart';
import '../../models/user.dart';
import '../../models/user_badge.dart';
import '../coverage/personal_map_screen.dart';
import '../poi/poi_thumbnail.dart';
import 'badge_display.dart';
import 'checkin_history_screen.dart';
import 'my_postcards_screen.dart';
import 'poi_grid_viewer_screen.dart';

/// SPEC §14 — stats, My Places, coverage, weekly leaderboard, sign-out. Replaces the
/// Account tab's placeholder in `main.dart`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _leaderboardShareKey = GlobalKey();
  bool _sharingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileControllerProvider.notifier).load());
  }

  /// SPEC §19 — shares a small dedicated "standing" card (handle/rank/cells), not a
  /// screenshot of the visible leaderboard list — that list can include other users'
  /// handles, which have no business ending up in someone else's shared image.
  Future<void> _shareLeaderboard() async {
    if (_sharingLeaderboard) return;
    setState(() => _sharingLeaderboard = true);
    try {
      final bytes = await captureRepaintBoundary(_leaderboardShareKey);
      if (bytes == null) return;
      await shareImageBytes(
        bytes,
        filename: 'my-leaderboard-rank.png',
        text: 'My Wanderpost leaderboard standing',
      );
    } finally {
      if (mounted) setState(() => _sharingLeaderboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final checkinOutbox = ref.watch(checkinOutboxControllerProvider);
    final poiOutbox = ref.watch(poiCreateOutboxControllerProvider);
    final outboxCount = checkinOutbox.items.length + poiOutbox.items.length;
    return Column(
      children: [
        if (outboxCount > 0)
          _OutboxBanner(
            count: outboxCount,
            replaying: checkinOutbox.replaying || poiOutbox.replaying,
          ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.read(profileControllerProvider.notifier).load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            loaded: (user, stats, map, coverageCount, leaderboard, badges) =>
                _buildLoaded(context, user, stats, map, coverageCount, leaderboard, badges),
          ),
        ),
      ],
    );
  }

  /// SPEC §21 — sets/clears the opt-in display name shown instead of the auto-generated
  /// `handle`. A profanity-flagged name comes back as an `ApiException` and is shown
  /// inline in the dialog rather than replacing the whole profile screen with an error.
  Future<void> _editDisplayName(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    String? errorText;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Display name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: 'Shown instead of your handle on your photos',
              errorText: errorText,
            ),
          ),
          actions: [
            if (current != null)
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(profileControllerProvider.notifier).setDisplayName(null);
                    if (context.mounted) Navigator.of(context).pop(true);
                  } on ApiException catch (e) {
                    setDialogState(() => errorText = e.message);
                  }
                },
                child: const Text('Clear'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => errorText = 'Enter a name, or tap Clear');
                  return;
                }
                try {
                  await ref.read(profileControllerProvider.notifier).setDisplayName(value);
                  if (context.mounted) Navigator.of(context).pop(true);
                } on ApiException catch (e) {
                  setDialogState(() => errorText = e.message);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result != true) return;
  }

  Widget _buildLoaded(
    BuildContext context,
    User user,
    MeStats stats,
    MeMap map,
    int coverageCount,
    LeaderboardResult leaderboard,
    List<UserBadge> badges,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.displayName ?? user.handle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit display name',
              onPressed: () => _editDisplayName(user.displayName),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${stats.checkins} check-ins · ${stats.cellsCovered} cells covered · '
          '${stats.poisCreated} places created · ${stats.creatorScore} creator score',
        ),
        const SizedBox(height: 4),
        Text('$coverageCount map cells explored'),
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in badges)
                Chip(
                  avatar: Icon(badgeIcon(badge.badgeKey), size: 18),
                  label: Text(badgeLabel(badge.badgeKey)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PersonalMapScreen()),
                ),
                child: const Text('View my map'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckinHistoryScreen()),
                ),
                child: const Text('Check-in history'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // SPEC §20 — the "my postcards" fast-follow: server-side revoke existed with
        // nothing in the UI to reach it until now.
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyPostcardsScreen()),
          ),
          child: const Text('My postcards'),
        ),
        const SizedBox(height: 24),
        Text('My places', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _PoiGrid(items: _myPlaces(map)),
        const SizedBox(height: 24),
        Text('Weekly leaderboard', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (leaderboard.me != null) ...[
          Row(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _leaderboardShareKey,
                  child: _LeaderboardShareCard(handle: user.handle, me: leaderboard.me!),
                ),
              ),
              IconButton(
                icon: _sharingLeaderboard
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                onPressed: _sharingLeaderboard ? null : _shareLeaderboard,
                tooltip: 'Share your standing',
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (leaderboard.entries.isEmpty) const Text('No coverage yet this week.'),
        for (final entry in leaderboard.entries)
          ListTile(
            leading: Text('#${entry.rank}'),
            title: Text(entry.handle),
            trailing: Text('${entry.cells} cells'),
          ),
        if (leaderboard.me != null && !leaderboard.entries.any((e) => e.rank == leaderboard.me!.rank))
          ListTile(
            leading: Text('#${leaderboard.me!.rank}'),
            title: const Text('You'),
            trailing: Text('${leaderboard.me!.cells} cells'),
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  /// SPEC §19 — `created` + `checkedIn`, deduplicated by id (a POI the caller both
  /// created and checked into shouldn't appear twice in the grid).
  List<PoiPin> _myPlaces(MeMap map) {
    final byId = <String, PoiPin>{};
    for (final poi in [...map.created, ...map.checkedIn]) {
      byId[poi.id] = poi;
    }
    return byId.values.toList();
  }
}

/// SPEC §17/§18 — the manual retry action, alongside the app-launch trigger in
/// `main.dart`. Not shown at all once both outboxes are empty (the common case). A
/// combined count across check-ins and POI creations, per §18 — one banner, not two.
class _OutboxBanner extends ConsumerWidget {
  final int count;
  final bool replaying;

  const _OutboxBanner({required this.count, required this.replaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(count == 1 ? '1 item waiting to sync' : '$count items waiting to sync'),
            ),
            if (replaying)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: () {
                  ref.read(checkinOutboxControllerProvider.notifier).replay();
                  ref.read(poiCreateOutboxControllerProvider.notifier).replay();
                },
                child: const Text('Retry now'),
              ),
          ],
        ),
      ),
    );
  }
}

/// SPEC §19 — the small rendered "share card" the leaderboard share action captures:
/// just the caller's own handle/rank/cells, deliberately not the visible leaderboard
/// list (which can include other users' handles).
class _LeaderboardShareCard extends StatelessWidget {
  final String handle;
  final MeStanding me;

  const _LeaderboardShareCard({required this.handle, required this.me});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(handle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Rank #${me.rank} this week · ${me.cells} cells covered'),
          ],
        ),
      ),
    );
  }
}

/// SPEC §19 — an Instagram-profile-style 3-column photo grid. Tapping a cell opens a
/// full-screen swipeable viewer across `items`, starting at the tapped one.
class _PoiGrid extends StatelessWidget {
  final List<PoiPin> items;

  const _PoiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Nothing yet — create a place or check in to get started.');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final poi = items[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PoiGridViewerScreen(items: items, initialIndex: index),
            ),
          ),
          child: PoiThumbnail(thumbnailUrl: poi.thumbnailUrl, category: poi.category),
        );
      },
    );
  }
}
