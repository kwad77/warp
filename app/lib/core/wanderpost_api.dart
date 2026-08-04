import '../models/checkin.dart';
import '../models/checkin_list_item.dart';
import '../models/coverage_heatmap_result.dart';
import '../models/gps_fix.dart';
import '../models/lat_lng.dart';
import '../models/leaderboard_result.dart';
import '../models/me_map.dart';
import '../models/me_stats.dart';
import '../models/photo.dart';
import '../models/poi.dart';
import '../models/poi_create_result.dart';
import '../models/poi_pin.dart';
import '../models/pois_result.dart';
import '../models/user.dart';
import '../models/user_badge.dart';
import 'api_client.dart';

/// Typed wrapper over [ApiClient] for exactly the SPEC §7 endpoints this slice (map,
/// browse, auth) needs. Every method throws [ApiException] on failure.
class WanderpostApi {
  final ApiClient client;

  WanderpostApi(this.client);

  Future<void> requestEmailCode(String email) async {
    await client.postJson('/v1/auth/email/request', body: {'email': email});
  }

  /// Returns the logged-in [User]; tokens are persisted by [ApiClient]'s caller.
  Future<({String accessToken, String refreshToken, User user})> verifyEmailCode(
    String email,
    String code,
  ) async {
    final body = await client.postJson(
      '/v1/auth/email/verify',
      body: {'email': email, 'code': code},
    );
    return (
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
      user: User.fromMap(body['user'] as Map<String, dynamic>),
    );
  }

  Future<PoisResult> pois({
    required double west,
    required double south,
    required double east,
    required double north,
    required int zoom,
  }) async {
    final body = await client.getJson(
      '/v1/pois',
      query: {'bbox': '$west,$south,$east,$north', 'zoom': zoom},
    );
    return PoisResult.fromMap(body);
  }

  Future<List<PoiPin>> nearby({
    required double lat,
    required double lng,
    int? radiusM,
  }) async {
    final body = await client.getJson(
      '/v1/pois/nearby',
      query: {'lat': lat, 'lng': lng, 'radiusM': ?radiusM},
    );
    return (body['pois'] as List<dynamic>)
        .map((e) => PoiPin.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Poi> poiDetail(String id) async {
    final body = await client.getJson('/v1/pois/$id');
    return Poi.fromMap(body['poi'] as Map<String, dynamic>);
  }

  /// SPEC §7 `POST /photos/:id/vote`. `upvote: false` retracts (`value: 0`).
  Future<int> voteOnPhoto(String photoId, {required bool upvote}) async {
    final body = await client.postJson(
      '/v1/photos/$photoId/vote',
      body: {'value': upvote ? 1 : 0},
    );
    return body['voteScore'] as int;
  }

  /// SPEC §7 `POST /reports`. `note` is optional, capped at 280 code points server-side.
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? note,
  }) async {
    await client.postJson(
      '/v1/reports',
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        'note': ?note,
      },
    );
  }

  /// SPEC §7/§19 `POST /pois/:id/save`. `save: false` retracts (`value: 0`).
  Future<bool> setSavedPoi(String poiId, {required bool save}) async {
    final body = await client.postJson(
      '/v1/pois/$poiId/save',
      body: {'value': save ? 1 : 0},
    );
    return body['saved'] as bool;
  }

  /// SPEC §7 `POST /pois` / §13.1. `force: true` skips the dedupe prompt server-side.
  Future<PoiCreateResult> createPoi({
    required String title,
    String? description,
    required String category,
    required LatLng location,
    required GpsFix gpsFix,
    bool force = false,
  }) async {
    final body = await client.postJson(
      '/v1/pois',
      body: {
        'title': title,
        'description': ?description,
        'category': category,
        'location': {'lat': location.lat, 'lng': location.lng},
        'gpsFix': gpsFix.toMap(),
        if (force) 'force': true,
      },
    );
    if (body.containsKey('dedupeCandidates')) {
      final candidates = (body['dedupeCandidates'] as List<dynamic>)
          .map((e) => PoiPin.fromMap(e as Map<String, dynamic>))
          .toList();
      return PoiCreateResult.dedupe(candidates);
    }
    return PoiCreateResult.created(Poi.fromMap(body['poi'] as Map<String, dynamic>));
  }

  /// SPEC §6/§7 `POST /pois/:id/photos/presign`. `source` is `poi_creation` or `checkin`.
  Future<({String uploadUrl, String storageKey, int maxBytes})> presignPhoto(
    String poiId, {
    required String contentType,
    required String source,
  }) async {
    final body = await client.postJson(
      '/v1/pois/$poiId/photos/presign',
      body: {'contentType': contentType, 'source': source},
    );
    return (
      uploadUrl: body['uploadUrl'] as String,
      storageKey: body['storageKey'] as String,
      maxBytes: body['maxBytes'] as int,
    );
  }

  /// SPEC §6/§7 `POST /pois/:id/photos/complete`. Idempotent server-side on retry.
  Future<Photo> completePhoto(
    String poiId, {
    required String storageKey,
    required String source,
  }) async {
    final body = await client.postJson(
      '/v1/pois/$poiId/photos/complete',
      body: {'storageKey': storageKey, 'source': source},
    );
    return Photo.fromMap(body['photo'] as Map<String, dynamic>);
  }

  /// SPEC §7/§13.2 `POST /devices`. `model` is intentionally omitted — no device-model
  /// lookup dependency for a field the server already treats as optional.
  Future<String> registerDevice({required String platform}) async {
    final body = await client.postJson('/v1/devices', body: {'platform': platform});
    return body['deviceId'] as String;
  }

  /// SPEC §5.1/§7 `POST /checkins/intent`.
  Future<({String nonce, int expiresInS})> checkinIntent({
    required String poiId,
    required String deviceId,
  }) async {
    final body = await client.postJson(
      '/v1/checkins/intent',
      body: {'poiId': poiId, 'deviceId': deviceId},
    );
    return (nonce: body['nonce'] as String, expiresInS: body['expiresInS'] as int);
  }

  /// SPEC §5/§7/§17 `POST /checkins`. `capture` is required for `mode: 'photo'` (§13.2).
  /// `evidence: 'deferred'` is the offline check-in outbox's replay path (§17) — the
  /// caller supplies the check-in's true, possibly hours-old `fixes`/`capture.capturedAt`.
  Future<Checkin> submitCheckin({
    required String nonce,
    required String poiId,
    required String mode,
    required List<GpsFix> fixes,
    required String integrityToken,
    String evidence = 'live',
    ({String token, String capturedAt, String storageKey})? capture,
  }) async {
    final body = await client.postJson(
      '/v1/checkins',
      body: {
        'nonce': nonce,
        'poiId': poiId,
        'mode': mode,
        'fixes': fixes.map((f) => f.toMap()).toList(),
        'integrityToken': integrityToken,
        'evidence': evidence,
        if (capture != null)
          'capture': {
            'token': capture.token,
            'capturedAt': capture.capturedAt,
            'storageKey': capture.storageKey,
          },
      },
    );
    return Checkin.fromMap(body['checkin'] as Map<String, dynamic>);
  }

  /// SPEC §7/§14 `GET /me`.
  Future<({User user, MeStats stats})> me() async {
    final body = await client.getJson('/v1/me');
    return (
      user: User.fromMap(body['user'] as Map<String, dynamic>),
      stats: MeStats.fromMap(body['stats'] as Map<String, dynamic>),
    );
  }

  /// SPEC §21 `PATCH /me/display-name`. `displayName: null` clears it (reverts to
  /// uncredited). A profanity-flagged name throws `ApiException` (`request/invalid`).
  Future<String?> setDisplayName(String? displayName) async {
    final body = await client.patchJson(
      '/v1/me/display-name',
      body: {'displayName': displayName},
    );
    return body['displayName'] as String?;
  }

  /// SPEC §7/§14 `GET /me/map`.
  Future<MeMap> meMap() async {
    final body = await client.getJson('/v1/me/map');
    return MeMap.fromMap(body);
  }

  /// SPEC §7/§14 `GET /me/coverage`.
  Future<({List<String> cells, int count})> meCoverage() async {
    final body = await client.getJson('/v1/me/coverage');
    return (
      cells: (body['cells'] as List<dynamic>).cast<String>(),
      count: body['count'] as int,
    );
  }

  /// SPEC §7/§15 `GET /me/coverage/heatmap`.
  Future<CoverageHeatmapResult> coverageHeatmap({required int zoom}) async {
    final body = await client.getJson('/v1/me/coverage/heatmap', query: {'zoom': zoom});
    return CoverageHeatmapResult.fromMap(body);
  }

  /// SPEC §7/§16 `GET /me/badges`, earned-order (not alphabetical).
  Future<List<UserBadge>> meBadges() async {
    final body = await client.getJson('/v1/me/badges');
    return (body['badges'] as List<dynamic>)
        .map((e) => UserBadge.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// SPEC §7 `GET /me/checkins`. Keyset-paginated; an absent `nextCursor` means no
  /// further pages.
  Future<({List<CheckinListItem> items, String? nextCursor})> meCheckins({
    String? cursor,
    int limit = 50,
  }) async {
    final body = await client.getJson(
      '/v1/me/checkins',
      query: {'limit': limit, 'cursor': ?cursor},
    );
    return (
      items: (body['items'] as List<dynamic>)
          .map((e) => CheckinListItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      nextCursor: body['nextCursor'] as String?,
    );
  }

  /// SPEC §7/§20 `POST /checkins/:id/postcards`.
  Future<String> sendPostcard(String checkinId, {String? message}) async {
    final body = await client.postJson(
      '/v1/checkins/$checkinId/postcards',
      body: {'message': ?message},
    );
    return (body['postcard'] as Map<String, dynamic>)['url'] as String;
  }

  /// SPEC §7/§14 `GET /leaderboards/coverage`.
  Future<LeaderboardResult> leaderboardCoverage({required String window}) async {
    final body = await client.getJson(
      '/v1/leaderboards/coverage',
      query: {'window': window, 'scope': 'global'},
    );
    return LeaderboardResult.fromMap(body);
  }
}
