import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/email_auth_screen.dart';
import 'features/map/map_screen.dart';
import 'features/profile/profile_screen.dart';

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
///
/// SPEC §17 — the offline check-in outbox is loaded once at app start, and replayed
/// opportunistically whenever the user is (or becomes) logged in — replay needs auth
/// (a fresh intent, `POST /devices` if the device isn't registered yet), so there's no
/// point attempting it before that. No background sync: this is the "app launch" trigger
/// the SPEC calls for; the other is a manual retry action (ProfileScreen).
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(checkinOutboxControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      next.maybeWhen(
        loggedIn: (_) => ref.read(checkinOutboxControllerProvider.notifier).replay(),
        orElse: () {},
      );
    });
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
              loggedIn: (user) => const ProfileScreen(),
              orElse: () => const EmailAuthScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
