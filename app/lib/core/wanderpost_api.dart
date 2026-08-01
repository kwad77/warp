import '../models/gps_fix.dart';
import '../models/lat_lng.dart';
import '../models/photo.dart';
import '../models/poi.dart';
import '../models/poi_create_result.dart';
import '../models/poi_pin.dart';
import '../models/pois_result.dart';
import '../models/user.dart';
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
}
