import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as mlgl;

import '../../core/constants.dart';
import '../../core/geo.dart';
import '../../core/providers.dart';
import '../../models/gps_fix.dart';
import '../../models/lat_lng.dart' as models;
import '../../models/poi_pin.dart';
import 'camera_capture_screen.dart';
import 'pending_photo.dart';
import 'poi_create_state.dart';

/// SPEC §13.1 — POI-creation form: pin adjustment, category/title/description, optional
/// camera/gallery photo (gated by on-device face detection), dedupe picker. Pops with the
/// new POI's id on success, or `null` if the user backs out.
class PoiCreateScreen extends ConsumerStatefulWidget {
  final models.LatLng initialLocation;

  const PoiCreateScreen({super.key, required this.initialLocation});

  @override
  ConsumerState<PoiCreateScreen> createState() => _PoiCreateScreenState();
}

class _PoiCreateScreenState extends ConsumerState<PoiCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = AppConfig.poiCategories.first;
  late models.LatLng _pinLocation = widget.initialLocation;
  GpsFix? _gpsFix;
  String? _locationError;
  PendingPhoto? _photo;
  mlgl.MapLibreMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadCurrentFix();
  }

  Future<void> _loadCurrentFix() async {
    try {
      final fix = await ref.read(locationSourceProvider).currentFix();
      if (!mounted) return;
      setState(() => _gpsFix = fix);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationError = 'Could not get your current location.');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? get _pinDistanceM {
    final fix = _gpsFix;
    if (fix == null) return null;
    return haversineM(_pinLocation, models.LatLng(lat: fix.lat, lng: fix.lng));
  }

  void _onCameraIdle() {
    final target = _mapController?.cameraPosition?.target;
    if (target == null) return;
    setState(() => _pinLocation = models.LatLng(lat: target.latitude, lng: target.longitude));
  }

  Future<void> _acceptCandidatePhoto(String path) async {
    final hasFace = await ref.read(faceGateProvider).hasFace(path);
    if (!mounted) return;
    if (hasFace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A person was detected — please retake without anyone in frame.'),
        ),
      );
      return;
    }
    setState(() => _photo = PendingPhoto(path: path, contentType: AppConfig.photoContentType));
  }

  Future<void> _takePhoto() async {
    final result = await Navigator.of(context).push<({String path, DateTime capturedAt})>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (result == null) return;
    await _acceptCandidatePhoto(result.path);
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _acceptCandidatePhoto(picked.path);
  }

  Future<void> _submit() async {
    final gpsFix = _gpsFix;
    final title = _titleController.text.trim();
    if (gpsFix == null || title.isEmpty) return;
    final description = _descriptionController.text.trim();
    await ref.read(poiCreateControllerProvider.notifier).submit(
          title: title,
          description: description.isEmpty ? null : description,
          category: _category,
          location: _pinLocation,
          gpsFix: gpsFix,
          photo: _photo,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poiCreateControllerProvider);
    ref.listen<PoiCreateState>(poiCreateControllerProvider, (previous, next) {
      next.whenOrNull(created: (poi) => Navigator.of(context).pop(poi.id));
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create a place')),
      body: state.maybeWhen(
        dedupe: (candidates) => _DedupePicker(
          candidates: candidates,
          onPick: (poiId) => Navigator.of(context).pop(poiId),
          onCreateAnyway: () => ref.read(poiCreateControllerProvider.notifier).forceCreateAnyway(),
        ),
        // SPEC §18 — no poi id exists yet for a queued creation, so this pops with null
        // (same as backing out) rather than an id there's nothing to show yet for.
        queued: () => _QueuedMessage(onDone: () => Navigator.of(context).pop()),
        orElse: () => _buildForm(context, state),
      ),
    );
  }

  Widget _buildForm(BuildContext context, PoiCreateState state) {
    final submitting = state.maybeWhen(submitting: () => true, orElse: () => false);
    final distanceM = _pinDistanceM;
    final pinTooFar = distanceM != null && distanceM > AppConfig.pinAdjustMaxM;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Drag the map so the pin sits on the place.'),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              mlgl.MapLibreMap(
                styleString: AppConfig.mapStyleUrl,
                initialCameraPosition: mlgl.CameraPosition(
                  target: mlgl.LatLng(widget.initialLocation.lat, widget.initialLocation.lng),
                  zoom: 17,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onCameraIdle: _onCameraIdle,
              ),
              const IgnorePointer(
                child: Center(child: Icon(Icons.location_pin, size: 40, color: Colors.red)),
              ),
            ],
          ),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_locationError!, style: const TextStyle(color: Colors.red)),
          ),
        if (pinTooFar)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Pin is ${distanceM.round()}m from your location (max ${AppConfig.pinAdjustMaxM.round()}m) — drag it closer.',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        state.maybeWhen(
          pinAdjustError: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'That pin is too far from your location — drag it closer and try again.',
              style: TextStyle(color: Colors.red),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description (optional)'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: AppConfig.poiCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
        ),
        const SizedBox(height: 16),
        const Text('Photo (optional, for creating places only):'),
        const SizedBox(height: 8),
        if (_photo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(_photo!.path), height: 160, fit: BoxFit.cover),
          ),
          TextButton(
            onPressed: () => setState(() => _photo = null),
            child: const Text('Remove photo'),
          ),
        ] else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take photo'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from gallery'),
              ),
            ],
          ),
        state.maybeWhen(
          photoBlocked: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'The photo shows a person and can\'t be used — please retake or choose another.',
              style: TextStyle(color: Colors.red),
            ),
          ),
          photoProcessingFailed: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Couldn't process that photo — please try a different one.",
              style: TextStyle(color: Colors.red),
            ),
          ),
          error: (message) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: submitting || _gpsFix == null || _titleController.text.trim().isEmpty
              ? null
              : _submit,
          child: submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create place'),
        ),
      ],
    );
  }
}

class _QueuedMessage extends StatelessWidget {
  final VoidCallback onDone;

  const _QueuedMessage({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text(
              'No connection — saved and will sync automatically once you\'re back online.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onDone, child: const Text('OK')),
          ],
        ),
      ),
    );
  }
}

class _DedupePicker extends StatelessWidget {
  final List<PoiPin> candidates;
  final void Function(String poiId) onPick;
  final VoidCallback onCreateAnyway;

  const _DedupePicker({
    required this.candidates,
    required this.onPick,
    required this.onCreateAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Is this place already here?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (final candidate in candidates)
          Card(
            child: ListTile(
              title: Text(candidate.title),
              subtitle: Text(candidate.category),
              onTap: () => onPick(candidate.id),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onCreateAnyway,
          child: const Text('None of these — create mine'),
        ),
      ],
    );
  }
}
