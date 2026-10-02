// Regression: forms used lazy ListViews, so a field scrolled far off-screen
// was disposed and Form.validate() silently skipped it (the save then went
// to the server). On a short screen the first field is far out of view
// when Save is tapped; it must still be validated, before any request.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const _short = Size(390, 420);

Future<void> _go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pumpAndSettle();
}

/// Scrolls to the bottom (keyboard closed), taps [label], returns to the top.
Future<void> _saveFromBottom(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final list = find.byType(Scrollable).hitTestable().first;
  await tester.scrollUntilVisible(find.text(label), 400, scrollable: list);
  await tester.drag(list, const Offset(0, -3000));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.drag(list, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('customer form validates the name even when it is off-screen', (tester) async {
    final customers = FakeCustomerRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      customers: customers,
      size: _short,
    );
    await _go(tester, AppRoutes.newCustomer);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile'), '98250 12345');
    await _saveFromBottom(tester, 'Save');
    expect(customers.created, isEmpty);
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('business details validate the name even when it is off-screen', (tester) async {
    final admin = FakeAdminRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      admin: admin,
      size: _short,
    );
    await _go(tester, AppRoutes.businessProfile);
    await tester.enterText(find.widgetWithText(TextFormField, 'Business name'), '   ');
    await _saveFromBottom(tester, 'Save');
    expect(admin.saved, isEmpty);
    expect(find.text('Required'), findsOneWidget);
  });
}
