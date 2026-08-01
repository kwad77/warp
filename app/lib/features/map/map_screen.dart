import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../models/lat_lng.dart' as models;
import '../poi/poi_create_screen.dart';
import '../poi/poi_detail_sheet.dart';
import 'map_query.dart';

/// SPEC §12 — MapLibre map with server-driven clustering. No client-side clustering
/// logic: renders whichever of `pois`/`clusters` the server returned non-empty.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController;
  Timer? _debounce;

  void _onCameraIdle() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _loadCurrentViewport);
  }

  Future<void> _loadCurrentViewport() async {
    final controller = _mapController;
    if (controller == null) return;
    final bounds = await controller.getVisibleRegion();
    final zoom = controller.cameraPosition?.zoom ?? 0;
    final bbox = BoundingBox(
      west: bounds.southwest.longitude,
      south: bounds.southwest.latitude,
      east: bounds.northeast.longitude,
      north: bounds.northeast.latitude,
    );
    await ref.read(mapControllerProvider.notifier).load(bbox, zoom);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// SPEC §13.1 — opens POI creation centered on the current viewport; on success shows
  /// the new POI's detail sheet.
  Future<void> _createPoi() async {
    final target = _mapController?.cameraPosition?.target;
    if (target == null) return;
    final poiId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PoiCreateScreen(
          initialLocation: models.LatLng(lat: target.latitude, lng: target.longitude),
        ),
      ),
    );
    if (poiId != null && mounted) {
      openPoiDetail(context, poiId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createPoi,
        child: const Icon(Icons.add_location_alt),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: AppConfig.mapStyleUrl,
            initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 2),
            onMapCreated: (controller) => _mapController = controller,
            onCameraIdle: _onCameraIdle,
            onStyleLoadedCallback: _loadCurrentViewport,
          ),
          if (mapState.errorMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    mapState.errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the POI detail bottom sheet for [poiId] (SPEC §12).
void openPoiDetail(BuildContext context, String poiId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PoiDetailSheet(poiId: poiId),
  );
}
