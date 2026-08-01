import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderpost/core/api_client.dart';
import 'package:wanderpost/core/providers.dart';
import 'package:wanderpost/core/secure_store.dart';
import 'package:wanderpost/core/token_store.dart';
import 'package:wanderpost/core/wanderpost_api.dart';
import 'package:wanderpost/features/checkin/checkin_screen.dart';

import '../../helpers/fake_adapter.dart';

/// SPEC §10's "flutter, M1 step 4" line originally called for a golden test of the
/// stamp animation frame. That, and a fuller tap-through-to-verified widget test, were
/// both attempted and abandoned here, not silently skipped: `testWidgets`'s
/// `AutomatedTestWidgetsFlutterBinding` pump loop never reliably drained the real Dio/
/// FakeAdapter async chain within a bounded number of `pump()` calls, with or without
/// `Stream.timeout()` in the mix, and `pumpAndSettle()` times out outright against the
/// `inProgress` state's indeterminate `CircularProgressIndicator`. The flow logic itself
/// (intent → fixes → photo → submit, every response branch) is exhaustively covered by
/// `checkin_controller_test.dart`'s plain (non-widget) tests, which don't hit this pump
/// interaction at all. This test instead covers what's reliably assertable at the widget
/// layer: the initial screen renders correctly under the real provider graph.
class _InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

void main() {
  testWidgets('renders the mode-choice screen under the real provider graph', (tester) async {
    final api = WanderpostApi(
      ApiClient(
        baseUrl: 'http://test',
        tokenStore: TokenStore(storage: _InMemorySecureStore()),
        dio: buildFakeDio(FakeAdapter()),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [wanderpostApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: CheckinScreen(poiId: 'poi1')),
      ),
    );

    expect(find.text('Check in'), findsOneWidget);
    expect(find.text('How do you want to check in?'), findsOneWidget);
    expect(find.text('Check in with a photo'), findsOneWidget);
    expect(find.text('Check in without a photo'), findsOneWidget);
  });
}
