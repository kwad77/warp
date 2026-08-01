import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../poi/camera_capture_screen.dart';
import 'device_registrar.dart';
import 'pending_checkin_photo.dart';

/// SPEC §13.2 — mode choice (photo/confirm), then drives `CheckinController.submit`.
class CheckinScreen extends ConsumerStatefulWidget {
  final String poiId;

  const CheckinScreen({super.key, required this.poiId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  Future<PendingCheckinPhoto?> _capturePhoto(String nonce) async {
    final result = await Navigator.of(context).push<({String path, DateTime capturedAt})>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (result == null) return null;
    return PendingCheckinPhoto(path: result.path, capturedAt: result.capturedAt);
  }

  Future<void> _start(String mode) async {
    final deviceId = await ensureDeviceId(
      ref.read(wanderpostApiProvider),
      ref.read(deviceStoreProvider),
    );
    if (!mounted) return;
    await ref.read(checkinControllerProvider.notifier).submit(
          poiId: widget.poiId,
          deviceId: deviceId,
          mode: mode,
          capturePhoto: mode == 'photo' ? _capturePhoto : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Check in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: state.when(
            idle: () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('How do you want to check in?'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _start('photo'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Check in with a photo'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _start('confirm'),
                  child: const Text('Check in without a photo'),
                ),
              ],
            ),
            inProgress: () => const CircularProgressIndicator(),
            verified: (checkin) => _Result(
              icon: Icons.check_circle,
              color: Colors.green,
              message: "You're checked in!",
            ),
            pending: (checkin) => const _Result(
              icon: Icons.hourglass_top,
              color: Colors.orange,
              message: 'Check-in submitted — pending review.',
            ),
            rejected: (reasons) => _Result(
              icon: Icons.error_outline,
              color: Colors.red,
              message: reasons.contains('photo_required')
                  ? "This account needs a photo to check in right now."
                  : "Couldn't verify this check-in (${reasons.join(', ')}).",
              retry: () => ref.read(checkinControllerProvider.notifier).resetToIdle(),
            ),
            duplicate: () => const _Result(
              icon: Icons.info_outline,
              color: Colors.grey,
              message: "You've already checked in here.",
            ),
            photoBlocked: () => _Result(
              icon: Icons.error_outline,
              color: Colors.red,
              message: 'A person was detected in the photo — please retake.',
              retry: () => _start('photo'),
            ),
            photoProcessingFailed: () => _Result(
              icon: Icons.error_outline,
              color: Colors.red,
              message: "Couldn't process that photo — please try again.",
              retry: () => _start('photo'),
            ),
            fixTimeout: () => _Result(
              icon: Icons.location_off,
              color: Colors.red,
              message: "Couldn't get a clear location fix — try again outdoors.",
              retry: () => ref.read(checkinControllerProvider.notifier).resetToIdle(),
            ),
            error: (message) => _Result(
              icon: Icons.error_outline,
              color: Colors.red,
              message: message,
              retry: () => ref.read(checkinControllerProvider.notifier).resetToIdle(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback? retry;

  const _Result({required this.icon, required this.color, required this.message, this.retry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
          ),
          child: Icon(icon, color: color, size: 72),
        ),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        if (retry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: retry, child: const Text('Try again')),
        ],
      ],
    );
  }
}
