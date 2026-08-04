import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'token_store.dart';

/// Dio wrapper: attaches the bearer token, retries once through
/// `POST /v1/auth/refresh` on a 401, and always throws [ApiException] (never a raw
/// [DioException]) so callers only ever handle one exception type. SPEC §12.
class ApiClient {
  final String baseUrl;
  final TokenStore tokenStore;

  /// Called once when a refresh attempt fails outright (refresh token itself invalid /
  /// reused) — the UI layer routes to the auth screen. Never called for plain network
  /// errors or for 🌐 endpoints that simply had no token to attach.
  final void Function()? onSessionExpired;

  late final Dio _dio;

  ApiClient({required this.baseUrl, required this.tokenStore, this.onSessionExpired, Dio? dio}) {
    _dio = dio ?? Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStore.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.startsWith('/v1/auth/');
          final alreadyRetried = error.requestOptions.extra['_retried'] == true;
          if (error.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
            return handler.next(error);
          }
          final refreshed = await _tryRefresh();
          if (!refreshed) {
            await tokenStore.clear();
            onSessionExpired?.call();
            return handler.next(error);
          }
          try {
            final retryOptions = error.requestOptions;
            retryOptions.extra['_retried'] = true;
            final token = await tokenStore.readAccessToken();
            if (token != null) retryOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(retryOptions);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      final accessToken = body?['accessToken'];
      final newRefreshToken = body?['refreshToken'];
      if (accessToken is! String || newRefreshToken is! String) return false;
      await tokenStore.save(accessToken: accessToken, refreshToken: newRefreshToken);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) async {
    return _unwrap(() => _dio.get<Map<String, dynamic>>(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    return _unwrap(() => _dio.post<Map<String, dynamic>>(path, data: body));
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? body}) async {
    return _unwrap(() => _dio.patch<Map<String, dynamic>>(path, data: body));
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    return _unwrap(() => _dio.delete<Map<String, dynamic>>(path));
  }

  Future<Map<String, dynamic>> _unwrap(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponseBody(e.response!.data, statusCode: e.response!.statusCode ?? 0);
      }
      throw ApiException.network;
    }
  }
}
