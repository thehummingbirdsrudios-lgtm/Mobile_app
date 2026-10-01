import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.text('Maal').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Search design, customer, order'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300)); // debounce
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a hint first, then grouped results', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await _openSearch(tester);
    expect(find.text('Search by design no., customer name or mobile, or order no.'), findsOneWidget);

    await _type(tester, 'kundan');
    expect(find.text('Designs'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Order #1045'), findsOneWidget);
    expect(find.text('Kundan Set'), findsOneWidget);
  });

  testWidgets('opening a design navigates and remembers the query for this user only', (tester) async {
    final search = FakeSearchRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      search: search,
    );
    await _openSearch(tester);
    await _type(tester, '1024');
    await tester.tap(find.widgetWithText(ListTile, '1024'));
    await tester.pumpAndSettle();
    expect(find.text('Weight: 42 g'), findsOneWidget); // product detail
    expect(search.recentByScope, {
      't-a/u-owner': ['1024'],
    });
  });

  testWidgets('recent searches are listed, reusable and clearable', (tester) async {
    final search = FakeSearchRepository()
      ..recentByScope['t-a/u-owner'] = ['patel']
      ..recentByScope['t-b/u-someone'] = ['other business query'];
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      search: search,
    );
    await _openSearch(tester);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('other business query'), findsNothing);

    await tester.tap(find.text('patel'));
    await tester.pumpAndSettle();
    expect(search.queries, ['patel']);
    expect(find.text('Patel Kundan Stores'), findsWidgets);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('patel'), findsNothing);
    expect(search.recentByScope.containsKey('t-a/u-owner'), isFalse);
  });

  testWidgets('no match explains what to try', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await _openSearch(tester);
    await _type(tester, 'zzz');
    expect(find.text('No match for “zzz”'), findsOneWidget);
  });

  testWidgets('a slow earlier response never overwrites newer results', (tester) async {
    final slow = Completer<void>();
    final search = FakeSearchRepository()..gates['kun'] = slow;
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      search: search,
    );
    await _openSearch(tester);
    await tester.enterText(find.byType(TextField), 'kun');
    await tester.pump(const Duration(milliseconds: 300));
    await _type(tester, '1045');
    expect(find.text('Order #1045'), findsOneWidget);
    expect(find.text('Designs'), findsNothing);

    slow.complete();
    await tester.pumpAndSettle();
    expect(find.text('Designs'), findsNothing);
    expect(find.text('Order #1045'), findsOneWidget);
  });

  testWidgets('failure offers retry', (tester) async {
    final search = FakeSearchRepository()..error = const AppFailure(FailureKind.network);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      search: search,
    );
    await _openSearch(tester);
    await _type(tester, 'kundan');
    expect(find.text('Check your internet connection.'), findsOneWidget);
    search.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Designs'), findsOneWidget);
  });

  testWidgets('back returns to the tab the user came from', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await _openSearch(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Kundan Set'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
