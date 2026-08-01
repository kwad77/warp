import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as mlgl;

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/share_image.dart';
import '../../models/lat_lng.dart' as models;
import '../map/map_query.dart';
import '../map/map_screen.dart';
import 'personal_map_state.dart';

/// SPEC §15 — the caller's own coverage: a heatmap at coarse zoom (country/state/city-
/// scale H3 tiers), individual pins (own postcards + nearby POIs) once zoomed in past the
/// pin-mode threshold `GET /pois` already uses. Tapping a heatmap cell zooms to its
/// centroid at the next tier — the same "tap a cluster to zoom in" gesture `MapScreen`
/// already uses for POI clusters, reused rather than re-invented.
class PersonalMapScreen extends ConsumerStatefulWidget {
  const PersonalMapScreen({super.key});

  @override
  ConsumerState<PersonalMapScreen> createState() => _PersonalMapScreenState();
}

class _PersonalMapScreenState extends ConsumerState<PersonalMapScreen> {
  static const _heatmapSourceId = 'personal-coverage-heatmap-source';
  static const _heatmapLayerId = 'personal-coverage-heatmap-layer';
  static const _emptyFeatureCollection = {'type': 'FeatureCollection', 'features': <Object>[]};

  mlgl.MapLibreMapController? _mapController;
  mlgl.CircleManager? _circleManager;
  Timer? _debounce;
  bool _heatmapLayerAdded = false;
  final _shareBoundaryKey = GlobalKey();
  bool _sharing = false;

  /// SPEC §19 — shares whatever's currently on screen. This is deliberately how
  /// MILESTONES.md's "shareable map image with precision controls" is satisfied: the
  /// already-built H3 zoom-tier heatmap (§15) *is* the precision control, so the shared
  /// image never shows anything finer than the current zoom's resolution.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await captureRepaintBoundary(_shareBoundaryKey);
      if (bytes == null) return;
      await shareImageBytes(bytes, filename: 'my-coverage-map.png', text: 'My Wanderpost map');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
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
    await ref.read(personalMapControllerProvider.notifier).load(bbox, zoom);
  }

  void _onMapCreated(mlgl.MapLibreMapController controller) {
    _mapController = controller;
    _circleManager = mlgl.CircleManager(controller, onTap: _onCircleTapped);
  }

  void _onCircleTapped(mlgl.Circle circle) {
    final poiId = circle.data?['poiId'] as String?;
    if (poiId != null) openPoiDetail(context, poiId);
  }

  /// SPEC §15 — heatmap layers have no per-feature tap callback (unlike `CircleManager`
  /// pins), so a tap in heatmap mode is resolved to the nearest cell's centroid instead.
  void _onMapClick(Point<double> point, mlgl.LatLng coordinates) {
    final state = ref.read(personalMapControllerProvider);
    if (state.mode != PersonalMapMode.heatmap) return;
    final tapped = nearestHeatmapCell(
      state.heatmapCells,
      models.LatLng(lat: coordinates.latitude, lng: coordinates.longitude),
    );
    if (tapped != null) {
      unawaited(_drillInto(mlgl.LatLng(tapped.centroid.lat, tapped.centroid.lng)));
    }
  }

  /// Zooms to a heatmap cell's centroid, one tier finer — the drill-down gesture.
  Future<void> _drillInto(mlgl.LatLng centroid) async {
    final controller = _mapController;
    if (controller == null) return;
    final currentZoom = controller.cameraPosition?.zoom ?? 0;
    await controller.animateCamera(
      mlgl.CameraUpdate.newLatLngZoom(centroid, currentZoom + 3),
    );
  }

  Future<void> _renderPins(PersonalMapState state) async {
    final manager = _circleManager;
    if (manager == null) return;
    await manager.clear();
    await manager.addAll([
      for (final poi in state.myPostcards)
        mlgl.Circle(
          'mine-${poi.id}',
          mlgl.CircleOptions(
            geometry: mlgl.LatLng(poi.location.lat, poi.location.lng),
            circleRadius: 8,
            circleColor: '#2e7d32',
            circleStrokeColor: '#ffffff',
            circleStrokeWidth: 2,
          ),
          {'poiId': poi.id},
        ),
      for (final poi in state.nearbyPois)
        mlgl.Circle(
          'nearby-${poi.id}',
          mlgl.CircleOptions(
            geometry: mlgl.LatLng(poi.location.lat, poi.location.lng),
            circleRadius: 6,
            circleColor: '#9e9e9e',
            circleStrokeColor: '#ffffff',
            circleStrokeWidth: 1,
          ),
          {'poiId': poi.id},
        ),
    ]);
  }

  Future<void> _clearPins() async {
    await _circleManager?.clear();
  }

  Map<String, Object> _heatmapFeatureCollection(PersonalMapState state) => {
        'type': 'FeatureCollection',
        'features': [
          for (final cell in state.heatmapCells)
            {
              'type': 'Feature',
              'properties': {'weight': cell.count},
              'geometry': {
                'type': 'Point',
                'coordinates': [cell.centroid.lng, cell.centroid.lat],
              },
            },
        ],
      };

  Future<void> _renderHeatmap(PersonalMapState state) async {
    final controller = _mapController;
    if (controller == null) return;
    final featureCollection = _heatmapFeatureCollection(state);
    if (!_heatmapLayerAdded) {
      await controller.addGeoJsonSource(_heatmapSourceId, featureCollection);
      await controller.addHeatmapLayer(
        _heatmapSourceId,
        _heatmapLayerId,
        const mlgl.HeatmapLayerProperties(
          heatmapWeight: ['get', 'weight'],
          heatmapRadius: 28,
          heatmapOpacity: 0.75,
        ),
      );
      _heatmapLayerAdded = true;
    } else {
      await controller.setGeoJsonSource(_heatmapSourceId, featureCollection);
    }
  }

  Future<void> _clearHeatmap() async {
    if (_heatmapLayerAdded) {
      await _mapController?.setGeoJsonSource(_heatmapSourceId, _emptyFeatureCollection);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalMapControllerProvider);
    ref.listen<PersonalMapState>(personalMapControllerProvider, (previous, next) {
      if (next.mode == PersonalMapMode.heatmap) {
        unawaited(_clearPins());
        unawaited(_renderHeatmap(next));
      } else {
        unawaited(_clearHeatmap());
        unawaited(_renderPins(next));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Map'),
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            onPressed: _sharing ? null : _share,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _shareBoundaryKey,
        child: Stack(
          children: [
            mlgl.MapLibreMap(
              styleString: AppConfig.mapStyleUrl,
              initialCameraPosition: const mlgl.CameraPosition(target: mlgl.LatLng(0, 0), zoom: 2),
              onMapCreated: _onMapCreated,
              onMapClick: _onMapClick,
              onCameraIdle: _onCameraIdle,
              onStyleLoadedCallback: _loadCurrentViewport,
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _Banner(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final PersonalMapState state;

  const _Banner({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.errorMessage != null) {
      return _bubble(state.errorMessage!, Colors.black87);
    }
    if (state.mode == PersonalMapMode.heatmap) {
      return _bubble(
        'Zoom in to see your postcards and nearby places. Tap a highlighted area to '
        'zoom in.',
        Colors.black54,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _bubble(String text, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
