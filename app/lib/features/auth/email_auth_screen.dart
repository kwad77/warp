import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// SPEC §12 — email-code auth only for this slice (Apple/Google are server 501s).
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.when(
          loggedOut: () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => controller.requestCode(_emailController.text.trim()),
                child: const Text('Send code'),
              ),
            ],
          ),
          codeSent: (email) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Enter the code sent to $email'),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '6-digit code'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => controller.verifyCode(email, _codeController.text.trim()),
                child: const Text('Verify'),
              ),
            ],
          ),
          loggedIn: (user) => Center(child: Text('Signed in as ${user.handle}')),
          error: (message) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => controller.requestCode(_emailController.text.trim()),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
