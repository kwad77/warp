import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Minimal fake [HttpClientAdapter] so tests don't need real network or a mock-http
/// package (none is in the SPEC §1 mobile allowlist). Routes are matched by
/// `"METHOD path"`; the last handler registered for a route wins, and each call is
/// recorded in [requests] for assertions.
class FakeAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _handlers = {};
  final List<RequestOptions> requests = [];

  void on(String method, String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['$method $path'] = handler;
  }

  void onJson(String method, String path, int statusCode, Map<String, dynamic> body) {
    on(method, path, (options) => _jsonResponse(statusCode, body));
  }

  ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
    final bytes = utf8.encode(jsonEncode(body));
    return ResponseBody.fromBytes(bytes, statusCode, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler = _handlers['${options.method} ${options.path}'];
    if (handler == null) {
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404, data: <String, dynamic>{}),
        type: DioExceptionType.badResponse,
      );
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio buildFakeDio(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  // Dio 5 treats non-2xx as an error by default; that's exactly the SPEC §3 behavior
  // ApiClient expects (it catches DioException and re-parses the envelope).
  return dio;
}
