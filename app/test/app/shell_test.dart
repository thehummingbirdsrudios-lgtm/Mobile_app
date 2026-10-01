import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/features/auth/auth.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  group('redirectFor (auth guard)', () {
    test('unknown identity always goes to splash', () {
      expect(redirectFor(const SessionUnknown(), AppRoutes.hisaab), AppRoutes.splash);
      expect(redirectFor(const SessionUnknown(), AppRoutes.splash), isNull);
    });

    test('signed out cannot reach app routes or deep links', () {
      expect(redirectFor(const SessionSignedOut(), AppRoutes.home), AppRoutes.login);
      expect(redirectFor(const SessionSignedOut(), '/more/legal/privacy'), AppRoutes.login);
      expect(redirectFor(const SessionSignedOut(), AppRoutes.login), isNull);
    });

    test('signed in skips auth pages but keeps deep links', () {
      const signedIn = SessionSignedIn(ownerSession);
      expect(redirectFor(signedIn, AppRoutes.login), AppRoutes.home);
      expect(redirectFor(signedIn, AppRoutes.splash), AppRoutes.home);
      expect(redirectFor(signedIn, AppRoutes.hisaab), isNull);
    });
  });

  testWidgets('system Back on another tab returns to Home before leaving', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await tester.tap(find.text('Maal'));
    await tester.pumpAndSettle();
    expect(find.text('This section is being built'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
  });

  testWidgets('logout returns to login and hides business data', (tester) async {
    final auth = FakeAuthRepository(restored: ownerSession);
    await pumpVepari(tester, auth: auth);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Namaskar 👋'), findsOneWidget);
    expect(find.text('Shree Jewels'), findsNothing);
    expect(auth.signOutCalls, 1);
  });

  testWidgets('wide screens use a navigation rail, same destinations', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      size: const Size(1280, 800),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  for (final locale in const [Locale('gu'), Locale('hi'), Locale('en')]) {
    for (final width in const [320.0, 360.0]) {
      testWidgets('6 tabs + home fit without overflow at ${width.toInt()}dp in ${locale.languageCode}', (tester) async {
        await pumpVepari(
          tester,
          auth: FakeAuthRepository(restored: ownerSession),
          locale: locale,
          size: Size(width, 640),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);
        for (final index in [1, 5]) {
          await tester.tap(find.byType(NavigationDestination).at(index));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
