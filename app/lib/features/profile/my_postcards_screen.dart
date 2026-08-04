import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/share_image.dart';
import '../../models/my_postcard.dart';

/// SPEC §20 — closes the "fast-follow" gap flagged when postcard sending shipped:
/// server-side revoke existed with nothing in the mobile UI to reach it. Lists every
/// sent postcard, newest first, including already-revoked ones (shown, not hidden, so
/// this reads as a real history rather than a shrinking active set).
class MyPostcardsScreen extends ConsumerStatefulWidget {
  const MyPostcardsScreen({super.key});

  @override
  ConsumerState<MyPostcardsScreen> createState() => _MyPostcardsScreenState();
}

class _MyPostcardsScreenState extends ConsumerState<MyPostcardsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(myPostcardsControllerProvider.notifier).load());
  }

  Future<void> _confirmRevoke(String postcardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke this postcard?'),
        content: const Text(
          'The shared link will stop working. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(myPostcardsControllerProvider.notifier).revoke(postcardId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myPostcardsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My postcards')),
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
                        onPressed: () => ref.read(myPostcardsControllerProvider.notifier).load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.postcards.isEmpty
                  ? const Center(child: Text('No postcards sent yet.'))
                  : ListView.builder(
                      itemCount: state.postcards.length,
                      itemBuilder: (context, index) =>
                          _PostcardTile(postcard: state.postcards[index], onRevoke: _confirmRevoke),
                    ),
    );
  }
}

class _PostcardTile extends StatelessWidget {
  final MyPostcard postcard;
  final void Function(String postcardId) onRevoke;

  const _PostcardTile({required this.postcard, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final revoked = postcard.revokedAt != null;
    return ListTile(
      leading: Icon(
        revoked ? Icons.link_off : Icons.mail_outline,
        color: revoked ? Colors.grey : null,
      ),
      title: Text(postcard.poiTitle),
      subtitle: Text(revoked ? 'Revoked' : 'Sent ${_shortDate(postcard.createdAt)}'),
      trailing: revoked
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share again',
                  onPressed: () => shareText(postcard.url),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Revoke',
                  onPressed: () => onRevoke(postcard.id),
                ),
              ],
            ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
