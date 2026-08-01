import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_exception.dart';

void main() {
  group('ApiException.fromResponseBody', () {
    test('parses the SPEC §3 envelope with details', () {
      final e = ApiException.fromResponseBody(
        {
          'error': {
            'code': 'rate/limited',
            'message': 'Too many requests',
            'details': {'retryAfterS': 60},
          },
        },
        statusCode: 429,
      );
      expect(e.code, 'rate/limited');
      expect(e.message, 'Too many requests');
      expect(e.details, {'retryAfterS': 60});
    });

    test('parses an envelope with no details', () {
      final e = ApiException.fromResponseBody(
        {
          'error': {'code': 'auth/missing', 'message': 'Authorization header required'},
        },
        statusCode: 401,
      );
      expect(e.code, 'auth/missing');
      expect(e.details, isNull);
    });

    test('falls back to a generic exception for a malformed body', () {
      final e = ApiException.fromResponseBody('not an envelope', statusCode: 500);
      expect(e.code, 'unknown/error');
      expect(e.message, contains('500'));
    });

    test('falls back to a generic exception for a null body', () {
      final e = ApiException.fromResponseBody(null, statusCode: 503);
      expect(e.code, 'unknown/error');
    });
  });
}
