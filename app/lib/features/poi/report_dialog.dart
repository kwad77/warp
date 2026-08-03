import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/providers.dart';

/// SPEC §7 `POST /reports`' closed reason set.
const _reasons = <String, String>{
  'people': 'Contains people',
  'unsafe': 'Unsafe location',
  'wrong_location': 'Wrong location',
  'duplicate': 'Duplicate',
  'other': 'Other',
};

/// SPEC §7 — a report card for either a POI or one of its photos. Reused from both the
/// detail sheet (POI) and each gallery photo.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required String targetId,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ReportDialog(targetType: targetType, targetId: targetId),
  );
}

class _ReportDialog extends ConsumerStatefulWidget {
  final String targetType;
  final String targetId;

  const _ReportDialog({required this.targetType, required this.targetId});

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  String _reason = _reasons.keys.first;
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(wanderpostApiProvider).report(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted')),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.targetType == 'poi' ? 'Report this place' : 'Report this photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: _reason,
            isExpanded: true,
            items: [
              for (final entry in _reasons.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _reason = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 280,
            decoration: const InputDecoration(hintText: 'Add a note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
