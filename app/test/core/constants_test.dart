import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/constants.dart';

void main() {
  group('AppConfig.resolveMediaUrl', () {
    test('prefixes a server-relative path with apiBaseUrl', () {
      expect(
        AppConfig.resolveMediaUrl('/media/thumb/photos/poi1/ph1.jpg'),
        '${AppConfig.apiBaseUrl}/media/thumb/photos/poi1/ph1.jpg',
      );
    });

    test('leaves an already-absolute http(s) URL untouched', () {
      expect(AppConfig.resolveMediaUrl('https://cdn.example/x.jpg'), 'https://cdn.example/x.jpg');
      expect(AppConfig.resolveMediaUrl('http://cdn.example/x.jpg'), 'http://cdn.example/x.jpg');
    });
  });
}
