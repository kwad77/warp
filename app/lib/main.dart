import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/email_auth_screen.dart';
import 'features/map/map_screen.dart';

void main() {
  runApp(const ProviderScope(child: WanderpostApp()));
}

class WanderpostApp extends StatelessWidget {
  const WanderpostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wanderpost',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const RootScreen(),
    );
  }
}

/// SPEC §12 — map browsing is unauthenticated (🌐); the auth screen is reached
/// explicitly, not gating the map. For this slice both are just tabs.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wanderpost'),
          bottom: const TabBar(tabs: [Tab(text: 'Map'), Tab(text: 'Account')]),
        ),
        body: TabBarView(
          children: [
            const MapScreen(),
            auth.maybeWhen(
              loggedIn: (user) => Center(child: Text('Signed in as ${user.handle}')),
              orElse: () => const EmailAuthScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
