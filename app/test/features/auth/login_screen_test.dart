import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('signed-out user lands on login (no business data visible)', (tester) async {
    final auth = FakeAuthRepository();
    await pumpVepari(tester, auth: auth);
    expect(find.text('Namaskar 👋'), findsOneWidget);
    expect(find.text('Shree Jewels'), findsNothing);
  });

  testWidgets('validates inline before calling the server', (tester) async {
    final auth = FakeAuthRepository();
    await pumpVepari(tester, auth: auth);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(auth.signInCalls, 0);

    await tester.enterText(field('Username'), 'raj esh');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Use only a–z, 0–9, dot and underscore'), findsOneWidget);
  });

  testWidgets('wrong password shows a plain message, never a technical error', (tester) async {
    final auth = FakeAuthRepository(
      signInError: const AppFailure(FailureKind.invalidCredentials, diagnostic: 'auth:400'),
    );
    await pumpVepari(tester, auth: auth);
    await tester.enterText(field('Username'), 'rajesh');
    await tester.enterText(field('Password'), 'wrong');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Username or password is wrong.'), findsOneWidget);
    expect(find.textContaining('auth:'), findsNothing);
  });

  testWidgets('rapid double tap submits once; success opens Home', (tester) async {
    final auth = FakeAuthRepository(signInResult: ownerSession)..signInGate = Completer<void>();
    await pumpVepari(tester, auth: auth);
    await tester.enterText(field('Username'), 'rajesh');
    await tester.enterText(field('Password'), 'secret');
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.tap(find.text('Login'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'busy state after the delay');
    auth.signInGate!.complete();
    await tester.pumpAndSettle();
    expect(auth.signInCalls, 1);
    expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
  });

  testWidgets('unconfigured build says so honestly', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(),
      config: const AppConfig(
        environment: 'test',
        supabaseUrl: '',
        supabasePublishableKey: '',
        loginDomain: 'x',
        appVersion: '0.1.0',
      ),
    );
    expect(find.text('Server not set up'), findsOneWidget);
  });
}
