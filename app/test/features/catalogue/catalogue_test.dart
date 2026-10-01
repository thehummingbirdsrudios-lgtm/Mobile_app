import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/catalogue/catalogue.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

const _managerStaff = UserSession(
  userId: 'u-staff2',
  tenantId: 't-a',
  username: 'kiran',
  displayName: 'Kiranbhai',
  businessName: 'Shree Jewels',
  role: MemberRole.staff,
  permissions: {Permission.catalogueManage},
);

Future<void> _openMaal(WidgetTester tester) async {
  await tester.tap(find.text('Maal').last);
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pumpAndSettle();
}

final _editorList = find.descendant(of: find.byType(ProductEditScreen), matching: find.byType(Scrollable)).first;

/// Form screens are lazy lists: scroll the target into view, then tap it.
Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: _editorList);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Scrolls up until [text] is on screen (fails the test if it never appears).
Future<void> _scrollBackTo(WidgetTester tester, String text) =>
    tester.scrollUntilVisible(find.text(text), -200, scrollable: _editorList);

Uint8List _jpeg() {
  final image = img.Image(width: 400, height: 300);
  img.fill(image, color: img.ColorRgb8(180, 140, 60));
  return img.encodeJpg(image);
}

void main() {
  testWidgets('grid shows designs with rate and opens detail on tap', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
    await _openMaal(tester);

    expect(find.text('Kundan Set'), findsOneWidget);
    expect(find.text('Jhumka'), findsOneWidget);
    expect(find.text('₹620'), findsOneWidget);

    await tester.tap(find.text('Kundan Set'));
    await tester.pumpAndSettle();
    expect(find.text('1024'), findsOneWidget);
    expect(find.text('Weight: 42 g'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('owner sees cost and supplier; staff never do', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await _go(tester, AppRoutes.product(productKundanId));
    expect(find.text('Only you can see this'), findsOneWidget);
    expect(find.text('Secret Supplier'), findsOneWidget);
  });

  testWidgets('staff detail has no private card and no edit action', (tester) async {
    // The server omits `private` for staff; the fake mirrors that.
    final catalogue = FakeCatalogueRepository(products: [_withoutPrivate(sampleProducts().first)]);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      catalogue: catalogue,
    );
    await _go(tester, AppRoutes.product(productKundanId));
    expect(find.text('Only you can see this'), findsNothing);
    expect(find.byTooltip('Edit'), findsNothing);
  });

  testWidgets('empty catalogue offers "Add design" only to managers', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      catalogue: FakeCatalogueRepository(products: []),
    );
    await _openMaal(tester);
    expect(find.text('No maal yet.'), findsOneWidget);
    expect(find.text('Add design'), findsNothing);
  });

  testWidgets('empty catalogue for a manager shows the add action', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: _managerStaff),
      catalogue: FakeCatalogueRepository(products: []),
    );
    await _openMaal(tester);
    expect(find.text('No maal yet.'), findsOneWidget);
    expect(find.text('Add design'), findsWidgets);
  });

  testWidgets('load failure shows retry and recovers', (tester) async {
    final catalogue = FakeCatalogueRepository()..pageError = const AppFailure(FailureKind.network);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      catalogue: catalogue,
    );
    await _openMaal(tester);
    expect(find.text('Check your internet connection.'), findsOneWidget);
    catalogue.pageError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Kundan Set'), findsOneWidget);
  });

  testWidgets('category chip filters the grid', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
    await _openMaal(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kundan'));
    await tester.pumpAndSettle();
    expect(find.text('Kundan Set'), findsOneWidget);
    expect(find.text('Jhumka'), findsNothing);
  });

  group('editor', () {
    testWidgets('validates inline before any request', (tester) async {
      final catalogue = FakeCatalogueRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        catalogue: catalogue,
      );
      await _go(tester, AppRoutes.editProduct());
      await tester.enterText(find.widgetWithText(TextFormField, 'Design no.'), 'bad no!');
      await _tapText(tester, 'Save');
      await _scrollBackTo(tester, 'Use letters, numbers, - / . _ (max 24)');
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Enter a valid amount'), findsOneWidget);
      expect(catalogue.products, hasLength(2));
    });

    testWidgets('creates a design, then offers photos', (tester) async {
      final catalogue = FakeCatalogueRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        catalogue: catalogue,
      );
      await _go(tester, AppRoutes.editProduct());
      await tester.enterText(find.widgetWithText(TextFormField, 'Design no.'), 'NK-77');
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Naksh Haar');
      await tester.enterText(find.widgetWithText(TextFormField, 'Rate (₹ per piece)'), '1,250');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (g)'), '38.5');
      await tester.scrollUntilVisible(
        find.text('Save the design first, then add photos.'),
        200,
        scrollable: _editorList,
      );
      await _tapText(tester, 'Save');

      final created = catalogue.products.last;
      expect(created.designNo, 'NK-77');
      expect(created.rate, const Money.paise(125000));
      expect(created.weightMg, 38500);
      await tester.scrollUntilVisible(find.text('Camera'), 200, scrollable: _editorList);
      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('a taken design number is shown on the field', (tester) async {
      final catalogue = FakeCatalogueRepository()..createError = const AppFailure(FailureKind.alreadyExists);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        catalogue: catalogue,
      );
      await _go(tester, AppRoutes.editProduct());
      await tester.enterText(find.widgetWithText(TextFormField, 'Design no.'), '1024');
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Copy');
      await tester.enterText(find.widgetWithText(TextFormField, 'Rate (₹ per piece)'), '100');
      await _tapText(tester, 'Save');
      await _scrollBackTo(tester, 'This design number already exists.');
    });

    testWidgets('rate is locked for staff without rate permission', (tester) async {
      final catalogue = FakeCatalogueRepository(products: [_withoutPrivate(sampleProducts().first)]);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: _managerStaff),
        catalogue: catalogue,
      );
      await _go(tester, AppRoutes.editProduct(productKundanId));
      expect(find.text('Only staff with rate permission can change rates.'), findsOneWidget);
      expect(find.text('Only you can see this'), findsNothing);

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Kundan Set Gold');
      await _tapText(tester, 'Save');
      expect(catalogue.updates, hasLength(1));
      final (id, draft, includeRate) = catalogue.updates.single;
      expect(id, productKundanId);
      expect(draft.name, 'Kundan Set Gold');
      expect(includeRate, isFalse);
    });

    testWidgets('a picked photo is processed and uploaded', (tester) async {
      final catalogue = FakeCatalogueRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        catalogue: catalogue,
        photos: FakePhotoPicker(_jpeg()),
      );
      await _go(tester, AppRoutes.editProduct(productKundanId));
      await _tapText(tester, 'Gallery');
      expect(catalogue.addedPhotos, hasLength(1));
      final (productId, upload) = catalogue.addedPhotos.single;
      expect(productId, productKundanId);
      expect(upload.tenantId, 't-a');
      expect(upload.originalMime, 'image/jpeg');
      expect(upload.sortOrder, 1);
      expect(find.text('Photo added'), findsOneWidget);
    });

    testWidgets('a file that is not an image is rejected with a clear message', (tester) async {
      final catalogue = FakeCatalogueRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        catalogue: catalogue,
        photos: FakePhotoPicker(Uint8List.fromList(List.filled(64, 7))),
      );
      await _go(tester, AppRoutes.editProduct(productKundanId));
      await _tapText(tester, 'Gallery');
      expect(catalogue.addedPhotos, isEmpty);
      expect(find.text('This file is not a usable photo.'), findsOneWidget);
    });
  });
}

ProductDetail _withoutPrivate(ProductDetail p) => ProductDetail(
  id: p.id,
  designNo: p.designNo,
  name: p.name,
  rate: p.rate,
  isAvailable: p.isAvailable,
  isArchived: p.isArchived,
  publishedAt: p.publishedAt,
  photos: p.photos,
  weightMg: p.weightMg,
  categoryId: p.categoryId,
  categoryName: p.categoryName,
);
