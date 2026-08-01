import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/models/checkin.dart';
import 'package:wanderpost/models/cluster.dart';
import 'package:wanderpost/models/coverage_heatmap_cell.dart';
import 'package:wanderpost/models/coverage_heatmap_result.dart';
import 'package:wanderpost/models/gps_fix.dart';
import 'package:wanderpost/models/lat_lng.dart';
import 'package:wanderpost/models/leaderboard_result.dart';
import 'package:wanderpost/models/me_map.dart';
import 'package:wanderpost/models/me_stats.dart';
import 'package:wanderpost/models/poi.dart';
import 'package:wanderpost/models/poi_create_result.dart';
import 'package:wanderpost/models/poi_pin.dart';
import 'package:wanderpost/models/pois_result.dart';
import 'package:wanderpost/models/queued_checkin.dart';
import 'package:wanderpost/models/queued_poi_creation.dart';

void main() {
  test('PoiPin.fromMap parses the SPEC §7 shape', () {
    final pin = PoiPin.fromMap({
      'id': 'p1',
      'title': 'Miradouro',
      'category': 'viewpoint',
      'location': {'lat': 38.7, 'lng': -9.1},
      'checkinCount': 5,
    });
    expect(pin.id, 'p1');
    expect(pin.location.lat, 38.7);
    expect(pin.checkinCount, 5);
    expect(pin.thumbnailUrl, isNull);
  });

  test('PoiPin.fromMap parses a present thumbnailUrl (SPEC §19)', () {
    final pin = PoiPin.fromMap({
      'id': 'p1',
      'title': 'Miradouro',
      'category': 'viewpoint',
      'location': {'lat': 38.7, 'lng': -9.1},
      'checkinCount': 5,
      'thumbnailUrl': '/media/thumb/photos/p1/ph1.jpg',
    });
    expect(pin.thumbnailUrl, '/media/thumb/photos/p1/ph1.jpg');
  });

  test('Cluster.fromMap parses centroid', () {
    final cluster = Cluster.fromMap({
      'h3': 'abcdef',
      'count': 12,
      'centroid': {'lat': 1.5, 'lng': 2.5},
    });
    expect(cluster.count, 12);
    expect(cluster.centroid.lng, 2.5);
  });

  test('PoisResult.fromMap parses pois and clusters independently', () {
    final result = PoisResult.fromMap({
      'pois': [
        {
          'id': 'p1',
          'title': 'x',
          'category': 'landmark',
          'location': {'lat': 1, 'lng': 2},
          'checkinCount': 1,
        },
      ],
      'clusters': <Map<String, dynamic>>[],
    });
    expect(result.pois, hasLength(1));
    expect(result.clusters, isEmpty);
  });

  test('Poi.fromMap parses the full shape including gallery and creator', () {
    final poi = Poi.fromMap({
      'id': 'poi1',
      'title': 'Torre',
      'category': 'landmark',
      'location': {'lat': 1, 'lng': 2},
      'checkinCount': 10,
      'description': 'A tower.',
      'creator': {'id': 'u1', 'handle': 'explorer_x'},
      'checkinRadiusM': 75,
      'gallery': [
        {
          'id': 'ph1',
          'urlCard': '/media/card/x',
          'urlThumb': '/media/thumb/x',
          'voteScore': 3,
          'uploader': {'handle': 'explorer_y'},
          'status': 'approved',
        },
      ],
    });
    expect(poi.creatorHandle, 'explorer_x');
    expect(poi.gallery.single.uploaderHandle, 'explorer_y');
    expect(poi.description, 'A tower.');
  });

  test('Poi.fromMap handles a null description', () {
    final poi = Poi.fromMap({
      'id': 'poi1',
      'title': 'Torre',
      'category': 'landmark',
      'location': {'lat': 1, 'lng': 2},
      'checkinCount': 0,
      'description': null,
      'creator': {'id': 'u1', 'handle': 'explorer_x'},
      'checkinRadiusM': 75,
      'gallery': <Map<String, dynamic>>[],
    });
    expect(poi.description, isNull);
    expect(poi.gallery, isEmpty);
  });

  test('GpsFix.toMap serializes capturedAt as UTC ISO-8601 with a trailing Z', () {
    final fix = GpsFix(
      lat: 38.7,
      lng: -9.1,
      accuracyM: 12.5,
      capturedAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
    );
    expect(fix.toMap(), {
      'lat': 38.7,
      'lng': -9.1,
      'accuracyM': 12.5,
      'capturedAt': '2026-03-04T05:06:07.000Z',
    });
  });

  test('GpsFix.fromMap round-trips through toMap (SPEC §17 outbox persistence)', () {
    final fix = GpsFix(
      lat: 38.7,
      lng: -9.1,
      accuracyM: 12.5,
      capturedAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
    );
    final roundTripped = GpsFix.fromMap(fix.toMap());
    expect(roundTripped, fix);
  });

  test('Checkin.fromMap parses evidence (SPEC §17)', () {
    final checkin = Checkin.fromMap({
      'id': 'c1',
      'poiId': 'poi1',
      'status': 'verified',
      'mode': 'confirm',
      'evidence': 'deferred',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'verifiedAt': '2026-01-01T00:00:00.000Z',
    });
    expect(checkin.evidence, 'deferred');
  });

  test('QueuedCheckin round-trips through toMap/fromMap, including a null photo', () {
    final queued = QueuedCheckin(
      id: 'q1',
      poiId: 'poi1',
      mode: 'confirm',
      fixes: [
        GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1)),
      ],
      attemptedAt: DateTime.utc(2026, 1, 1, 0, 0, 30),
    );
    final roundTripped = QueuedCheckin.fromMap(queued.toMap());
    expect(roundTripped, queued);
  });

  test('QueuedCheckin round-trips a photo path and capturedAt', () {
    final queued = QueuedCheckin(
      id: 'q1',
      poiId: 'poi1',
      mode: 'photo',
      fixes: [
        GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1)),
      ],
      attemptedAt: DateTime.utc(2026, 1, 1, 0, 0, 30),
      photoPath: '/tmp/q1.jpg',
      photoCapturedAt: DateTime.utc(2026, 1, 1, 0, 0, 9),
    );
    final roundTripped = QueuedCheckin.fromMap(queued.toMap());
    expect(roundTripped, queued);
  });

  test('QueuedPoiCreation round-trips through toMap/fromMap, including a null description', () {
    final queued = QueuedPoiCreation(
      id: 'q1',
      title: 'Torre',
      category: 'landmark',
      location: const LatLng(lat: 38.7, lng: -9.1),
      gpsFix: GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1)),
    );
    final roundTripped = QueuedPoiCreation.fromMap(queued.toMap());
    expect(roundTripped, queued);
    expect(queued.toMap().containsKey('description'), isFalse);
  });

  test('QueuedPoiCreation round-trips a description and photo path', () {
    final queued = QueuedPoiCreation(
      id: 'q1',
      title: 'Torre',
      description: 'A tower',
      category: 'landmark',
      location: const LatLng(lat: 38.7, lng: -9.1),
      gpsFix: GpsFix(lat: 38.7, lng: -9.1, accuracyM: 10, capturedAt: DateTime.utc(2026, 1, 1)),
      photoPath: '/tmp/q1.jpg',
    );
    final roundTripped = QueuedPoiCreation.fromMap(queued.toMap());
    expect(roundTripped, queued);
  });

  test('PoiCreateResult distinguishes created vs dedupe', () {
    const poi = Poi(
      id: 'poi1',
      title: 'Torre',
      category: 'landmark',
      location: LatLng(lat: 1, lng: 2),
      checkinCount: 0,
      creatorId: 'u1',
      creatorHandle: 'explorer_x',
      checkinRadiusM: 75,
      gallery: [],
    );
    const pin = PoiPin(
      id: 'p1',
      title: 'Existing',
      category: 'landmark',
      location: LatLng(lat: 1, lng: 2),
      checkinCount: 3,
    );

    const created = PoiCreateResult.created(poi);
    const dedupe = PoiCreateResult.dedupe([pin]);

    expect(created.maybeWhen(created: (p) => p.id, orElse: () => null), 'poi1');
    expect(dedupe.maybeWhen(dedupe: (c) => c.single.id, orElse: () => null), 'p1');
  });

  test('MeStats.fromMap parses the SPEC §7 GET /me stats shape', () {
    final stats = MeStats.fromMap({'checkins': 5, 'cellsCovered': 3, 'poisCreated': 1});
    expect(stats.checkins, 5);
    expect(stats.cellsCovered, 3);
    expect(stats.poisCreated, 1);
  });

  test('MeMap.fromMap parses checkedIn/created/saved/vaulted independently (SPEC §19)', () {
    final meMap = MeMap.fromMap({
      'checkedIn': [
        {
          'id': 'p1',
          'title': 'A',
          'category': 'landmark',
          'location': {'lat': 1, 'lng': 2},
          'checkinCount': 1,
        },
      ],
      'created': <Map<String, dynamic>>[],
      'saved': [
        {
          'id': 'p2',
          'title': 'B',
          'category': 'viewpoint',
          'location': {'lat': 3, 'lng': 4},
          'checkinCount': 0,
          'thumbnailUrl': '/media/thumb/photos/p2/ph1.jpg',
        },
      ],
      'vaulted': <Map<String, dynamic>>[],
    });
    expect(meMap.checkedIn, hasLength(1));
    expect(meMap.created, isEmpty);
    expect(meMap.saved, hasLength(1));
    expect(meMap.saved.single.thumbnailUrl, '/media/thumb/photos/p2/ph1.jpg');
    expect(meMap.vaulted, isEmpty);
  });

  test('LeaderboardResult.fromMap parses entries and an absent me', () {
    final result = LeaderboardResult.fromMap({
      'entries': [
        {'rank': 1, 'handle': 'explorer_x', 'cells': 10},
      ],
    });
    expect(result.entries.single.handle, 'explorer_x');
    expect(result.me, isNull);
  });

  test('CoverageHeatmapCell.fromMap parses the SPEC §15 shape', () {
    final cell = CoverageHeatmapCell.fromMap({
      'h3': 'abc123',
      'count': 4,
      'centroid': {'lat': 38.7, 'lng': -9.1},
    });
    expect(cell.h3, 'abc123');
    expect(cell.count, 4);
    expect(cell.centroid.lat, 38.7);
  });

  test('CoverageHeatmapResult.fromMap parses cells and a present resolution', () {
    final result = CoverageHeatmapResult.fromMap({
      'cells': [
        {
          'h3': 'abc123',
          'count': 4,
          'centroid': {'lat': 38.7, 'lng': -9.1},
        },
      ],
      'resolution': 5,
    });
    expect(result.cells, hasLength(1));
    expect(result.resolution, 5);
  });

  test('CoverageHeatmapResult.fromMap parses a null resolution (pin-mode zoom)', () {
    final result = CoverageHeatmapResult.fromMap({
      'cells': <Map<String, dynamic>>[],
      'resolution': null,
    });
    expect(result.cells, isEmpty);
    expect(result.resolution, isNull);
  });

  test('LeaderboardResult.fromMap parses a present me (no handle)', () {
    final result = LeaderboardResult.fromMap({
      'entries': <Map<String, dynamic>>[],
      'me': {'rank': 42, 'cells': 3},
    });
    expect(result.me, isNotNull);
    expect(result.me!.rank, 42);
    expect(result.me!.cells, 3);
  });
}
