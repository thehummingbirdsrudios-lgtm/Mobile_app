import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets('owner sees today in seconds with Indian-formatted money', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
    expect(find.text("What's happening today?"), findsOneWidget);
    expect(find.text('₹38,500'), findsOneWidget);
    expect(find.text('₹22,000'), findsOneWidget);
    expect(find.text('₹4,82,000'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });

  testWidgets('staff without reports.view never triggers the dashboard call', (tester) async {
    final dashboard = FakeDashboardRepository(summary: sampleSummary);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      dashboard: dashboard,
    );
    expect(find.text("What's happening today?"), findsNothing);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(dashboard.calls, 0);
  });

  testWidgets('network error shows retry; retry recovers', (tester) async {
    final dashboard = FakeDashboardRepository(error: const AppFailure(FailureKind.network));
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      dashboard: dashboard,
    );
    expect(find.text('Check your internet connection.'), findsOneWidget);
    dashboard
      ..error = null
      ..summary = sampleSummary;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('₹4,82,000'), findsOneWidget);
  });

  testWidgets('quick action navigates to the Hisaab tab', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await tester.tap(find.widgetWithText(InkWell, 'Hisaab').first);
    await tester.pumpAndSettle();
    expect(find.text('Patel Kundan Stores'), findsOneWidget); // Baki list
    expect(find.text('₹48,200'), findsOneWidget);
  });
}
