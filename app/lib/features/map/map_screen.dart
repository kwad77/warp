import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../models/lat_lng.dart' as models;
import '../../models/pois_result.dart';
import '../poi/poi_create_screen.dart';
import '../poi/poi_detail_sheet.dart';
import 'map_query.dart';
import 'map_view_state.dart';

/// SPEC §12 — MapLibre map with server-driven clustering. No client-side clustering
/// logic: renders whichever of `pois`/`clusters` the server returned non-empty, as
/// `CircleManager` circles (individual POIs tap straight to the detail sheet; clusters
/// tap to zoom into their centroid, the same "tap to drill in" gesture `PersonalMapScreen`
/// already uses for its own heatmap cells).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController;
  CircleManager? _circleManager;
  Timer? _debounce;

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _circleManager = CircleManager(controller, onTap: _onCircleTapped);
  }

  void _onCircleTapped(Circle circle) {
    final poiId = circle.data?['poiId'] as String?;
    if (poiId != null) {
      openPoiDetail(context, poiId);
      return;
    }
    final clusterLat = circle.data?['clusterLat'] as double?;
    final clusterLng = circle.data?['clusterLng'] as double?;
    if (clusterLat != null && clusterLng != null) {
      unawaited(_drillIntoCluster(LatLng(clusterLat, clusterLng)));
    }
  }

  /// Zooms into a cluster's centroid, one tier finer — the same drill-down gesture
  /// `PersonalMapScreen._drillInto` uses for heatmap cells.
  Future<void> _drillIntoCluster(LatLng centroid) async {
    final controller = _mapController;
    if (controller == null) return;
    final currentZoom = controller.cameraPosition?.zoom ?? 0;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(centroid, currentZoom + 2));
  }

  Future<void> _renderMarkers(PoisResult result) async {
    final manager = _circleManager;
    if (manager == null) return;
    await manager.clear();
    await manager.addAll([
      for (final poi in result.pois)
        Circle(
          'poi-${poi.id}',
          CircleOptions(
            geometry: LatLng(poi.location.lat, poi.location.lng),
            circleRadius: 7,
            circleColor: '#1e88e5',
            circleStrokeColor: '#ffffff',
            circleStrokeWidth: 2,
          ),
          {'poiId': poi.id},
        ),
      for (final cluster in result.clusters)
        Circle(
          'cluster-${cluster.h3}',
          CircleOptions(
            geometry: LatLng(cluster.centroid.lat, cluster.centroid.lng),
            circleRadius: clusterRadius(cluster.count),
            circleColor: '#f57c00',
            circleStrokeColor: '#ffffff',
            circleStrokeWidth: 2,
            circleOpacity: 0.85,
          ),
          {'clusterLat': cluster.centroid.lat, 'clusterLng': cluster.centroid.lng},
        ),
    ]);
  }

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
    ref.listen<MapViewState>(
      mapControllerProvider,
      (previous, next) => unawaited(_renderMarkers(next.result)),
    );
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
            onMapCreated: _onMapCreated,
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
