/// Parses the SPEC §3 error envelope: `{error: {code, message, details}}`.
///
/// [code] is a client-local synthetic code ('auth/session_expired') for cases that never
/// come from the server (refresh failed) — never returned by the API itself, but treated
/// identically by callers pattern-matching on `code`.
class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ApiException({required this.code, required this.message, this.details});

  factory ApiException.fromResponseBody(Object? body, {required int statusCode}) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code'];
        final message = error['message'];
        return ApiException(
          code: code is String ? code : 'unknown/error',
          message: message is String ? message : 'Request failed ($statusCode)',
          details: error['details'] is Map<String, dynamic>
              ? error['details'] as Map<String, dynamic>
              : null,
        );
      }
    }
    return ApiException(code: 'unknown/error', message: 'Request failed ($statusCode)');
  }

  static const sessionExpired = ApiException(
    code: 'auth/session_expired',
    message: 'Your session has expired. Please sign in again.',
  );

  static const network = ApiException(
    code: 'network/unreachable',
    message: 'Could not reach the server. Check your connection and try again.',
  );

  @override
  String toString() => 'ApiException($code, $message)';
}
