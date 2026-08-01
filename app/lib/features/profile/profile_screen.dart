import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/leaderboard_result.dart';
import '../../models/me_map.dart';
import '../../models/me_stats.dart';
import '../../models/user.dart';
import '../checkin/checkin_outbox_state.dart';
import '../coverage/personal_map_screen.dart';
import '../map/map_screen.dart';

/// SPEC §14 — stats, My Places, coverage, weekly leaderboard, sign-out. Replaces the
/// Account tab's placeholder in `main.dart`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final outbox = ref.watch(checkinOutboxControllerProvider);
    return Column(
      children: [
        if (outbox.items.isNotEmpty) _OutboxBanner(outbox: outbox),
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
            loaded: (user, stats, map, coverageCount, leaderboard) =>
                _buildLoaded(context, user, stats, map, coverageCount, leaderboard),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    User user,
    MeStats stats,
    MeMap map,
    int coverageCount,
    LeaderboardResult leaderboard,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(user.handle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${stats.checkins} check-ins · ${stats.cellsCovered} cells covered · '
          '${stats.poisCreated} places created',
        ),
        const SizedBox(height: 4),
        Text('$coverageCount map cells explored'),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PersonalMapScreen()),
          ),
          child: const Text('View my map'),
        ),
        const SizedBox(height: 24),
        Text('My places', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (map.created.isEmpty && map.checkedIn.isEmpty)
          const Text('Nothing yet — create a place or check in to get started.')
        else ...[
          if (map.created.isNotEmpty) ...[
            const Text('Created', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final poi in map.created)
              ListTile(
                title: Text(poi.title),
                subtitle: Text(poi.category),
                onTap: () => openPoiDetail(context, poi.id),
              ),
          ],
          if (map.checkedIn.isNotEmpty) ...[
            const Text('Checked in', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final poi in map.checkedIn)
              ListTile(
                title: Text(poi.title),
                subtitle: Text(poi.category),
                onTap: () => openPoiDetail(context, poi.id),
              ),
          ],
        ],
        const SizedBox(height: 24),
        Text('Weekly leaderboard', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
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
}

/// SPEC §17 — the manual retry action, alongside the app-launch trigger in `main.dart`.
/// Not shown at all once the outbox is empty (the common case).
class _OutboxBanner extends ConsumerWidget {
  final CheckinOutboxState outbox;

  const _OutboxBanner({required this.outbox});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = outbox.items.length;
    return Material(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 1 ? '1 check-in waiting to sync' : '$count check-ins waiting to sync',
              ),
            ),
            if (outbox.replaying)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: () => ref.read(checkinOutboxControllerProvider.notifier).replay(),
                child: const Text('Retry now'),
              ),
          ],
        ),
      ),
    );
  }
}
