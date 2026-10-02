import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/features/settings/settings.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

class _Status implements AppStatusRepository {
  _Status(this.status);

  AppStatus? status;
  int calls = 0;

  @override
  Future<AppStatus?> fetch() async {
    calls++;
    return status;
  }
}

void main() {
  group('AppStatus.blocks', () {
    const min = AppStatus(minAppVersion: '1.4.2', maintenance: false);
    test('compares major, minor, patch numerically', () {
      expect(min.blocks('1.4.1'), isTrue);
      expect(min.blocks('1.3.99'), isTrue);
      expect(min.blocks('0.9.0'), isTrue);
      expect(min.blocks('1.4.2'), isFalse);
      expect(min.blocks('1.10.0'), isFalse);
      expect(min.blocks('2.0.0+build.7'), isFalse);
    });

    test('unparseable versions never lock anyone out', () {
      expect(min.blocks('dev'), isFalse);
      expect(const AppStatus(minAppVersion: 'garbage', maintenance: false).blocks('0.0.1'), isFalse);
    });
  });

  testWidgets('an outdated build is blocked with a clear message and can re-check', (tester) async {
    final status = _Status(const AppStatus(minAppVersion: '9.0.0', maintenance: false));
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      extraOverrides: [appStatusRepositoryProvider.overrideWithValue(status)],
    );
    expect(find.text('Update Vepari to continue'), findsOneWidget);
    expect(find.textContaining('This version (0.1.0) is no longer supported'), findsOneWidget);
    expect(find.text('Namaskar Rajeshbhai 👋'), findsNothing);

    status.status = const AppStatus(minAppVersion: '0.1.0', maintenance: false);
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
  });

  testWidgets('maintenance shows a banner and keeps the app usable', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      extraOverrides: [
        appStatusRepositoryProvider.overrideWithValue(
          _Status(const AppStatus(minAppVersion: '0.0.0', maintenance: true)),
        ),
      ],
    );
    expect(find.textContaining('saving is paused'), findsOneWidget);
    expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
  });

  testWidgets('when the status cannot be read the app runs normally', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      extraOverrides: [appStatusRepositoryProvider.overrideWithValue(_Status(null))],
    );
    expect(find.text('Update Vepari to continue'), findsNothing);
    expect(find.textContaining('saving is paused'), findsNothing);
    expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
  });
}
