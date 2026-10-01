import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/catalogue/catalogue.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

ProductDetail _recent(int i) => ProductDetail(
  id: '00000000-0000-4000-8000-${(2000 + i).toString().padLeft(12, '0')}',
  designNo: 'N$i',
  name: 'New $i',
  rate: const Money.paise(10000),
  isAvailable: true,
  isArchived: false,
  publishedAt: DateTime.now().subtract(Duration(hours: i)),
  photos: const [],
);

Future<void> _openFromHome(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(InkWell, 'Navo Maal').first);
  await tester.pumpAndSettle();
}

void main() {
  test('Navo Maal window is the last 7 days, stable to the minute', () {
    final f = CatalogueFilter.navoMaal(DateTime.utc(2026, 10, 8, 15, 42, 37));
    expect(f.newSince, DateTime.utc(2026, 10, 1, 15, 42));
    expect(f, CatalogueFilter.navoMaal(DateTime.utc(2026, 10, 8, 15, 42, 59)));
  });

  testWidgets('home quick action shows only designs from the last 7 days', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await _openFromHome(tester);
    expect(find.text('Added in the last 7 days'), findsOneWidget);
    expect(find.text('Kundan Set'), findsOneWidget);
    expect(find.text('Jhumka'), findsNothing); // 30 days old
  });

  testWidgets('without a share action there is no selection mode', (tester) async {
    // Catalogue on its own (no sharing module composed in).
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession), crossModule: false);
    await _openFromHome(tester);
    expect(find.text('Select to share'), findsNothing);
  });

  testWidgets('select designs and share them together', (tester) async {
    final shared = <List<String>>[];
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      catalogue: FakeCatalogueRepository(products: [_recent(1), _recent(2), _recent(3)]),
      crossModule: false,
      extraOverrides: [
        productActionsProvider.overrideWithValue(
          ProductActions(onShareMany: (products) async => shared.add([for (final p in products) p.designNo])),
        ),
      ],
    );
    await _openFromHome(tester);
    await tester.tap(find.text('Select to share'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);
    await tester.tap(find.text('New 1'));
    await tester.tap(find.text('New 3'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Share 2'));
    await tester.pumpAndSettle();
    expect(shared, [
      ['N1', 'N3'],
    ]);
    expect(find.text('Select to share'), findsOneWidget); // selection ended
  });

  testWidgets('selection is capped so one WhatsApp send stays reliable', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      size: const Size(1200, 2400),
      catalogue: FakeCatalogueRepository(products: [for (var i = 1; i <= 11; i++) _recent(i)]),
      crossModule: false,
      extraOverrides: [productActionsProvider.overrideWithValue(ProductActions(onShareMany: (_) async {}))],
    );
    await _openFromHome(tester);
    await tester.tap(find.text('Select to share'));
    await tester.pumpAndSettle();
    for (var i = 1; i <= 11; i++) {
      await tester.tap(find.text('New $i'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('10 selected'), findsOneWidget);
    expect(find.text('You can share up to 10 designs at once.'), findsOneWidget);
  });

  testWidgets('empty Navo Maal invites managers to add a design', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      catalogue: FakeCatalogueRepository(products: []),
    );
    await _openFromHome(tester);
    expect(find.text('No new designs in the last 7 days.'), findsOneWidget);
    expect(find.text('Add design'), findsOneWidget);
  });
}
