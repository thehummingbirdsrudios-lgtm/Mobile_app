import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('ignores taps while busy (no double submission)', (tester) async {
    final gate = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _host(
        AppButton(
          label: 'Order Karo',
          onPressed: () async {
            calls++;
            await gate.future;
          },
        ),
      ),
    );
    await tester.tap(find.text('Order Karo'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
    }
    gate.complete();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('fast actions never flash a spinner', (tester) async {
    await tester.pumpWidget(_host(AppButton(label: 'Save', onPressed: () async {})));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('shows success check only when asked and only after completion', (tester) async {
    await tester.pumpWidget(_host(AppButton(label: 'Save Payment', confirmSuccess: true, onPressed: () async {})));
    await tester.tap(find.text('Save Payment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SuccessCheck), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Save Payment'), findsOneWidget);
  });

  testWidgets('errors reset the button and reach onError; no success shown', (tester) async {
    Object? caught;
    await tester.pumpWidget(
      _host(
        AppButton(
          label: 'Send',
          confirmSuccess: true,
          onError: (e) => caught = e,
          onPressed: () async => throw const AppFailure(FailureKind.network),
        ),
      ),
    );
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(caught, isA<AppFailure>());
    expect(find.byType(SuccessCheck), findsNothing);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('disabled button is announced as disabled', (tester) async {
    await tester.pumpWidget(_host(const AppButton(label: 'Order Karo', onPressed: null)));
    final semantics = tester.getSemantics(find.byType(AppButton));
    expect(semantics.flagsCollection.isEnabled, isNot(true));
  });
}
