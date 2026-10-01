import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/orders/domain/orders.dart' show OrderCustomer, OrderLine;
import 'package:vepari/features/orders/orders.dart';
import 'package:vepari/features/sharing/data/remote/sharing_api.dart';
import 'package:vepari/features/sharing/sharing.dart';
import 'package:vepari/l10n/app_localizations_en.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

/// The product page is a CustomScrollView with a tall SliverAppBar: drag
/// like a user does, then tap Share.
Future<void> _tapPageShare(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -2000));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Share'));
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

const _kundan = ShareableProduct(
  designNo: '1024',
  name: 'Kundan Set',
  rate: Money.paise(62000),
  weightMg: 42000,
  businessName: 'Shree Jewels',
  whatsappPhone: '9825000000',
  watermark: true,
);

void main() {
  group('caption', () {
    test('lists each design with rate and weight, then the business', () {
      expect(buildShareCaption(AppLocalizationsEn(), [_kundan], const ShareOptions()), '''
1024 · Kundan Set
₹620 per piece · 42 g

— Shree Jewels
WhatsApp 9825000000''');
    });

    test('rate can be left out', () {
      final caption = buildShareCaption(AppLocalizationsEn(), [_kundan], const ShareOptions(showRate: false));
      expect(caption, isNot(contains('₹')));
      expect(caption, contains('42 g'));
    });
  });

  test('share payload decoding ignores anything outside the allow-list', () {
    final p = shareableProductFromJson({
      'design_no': '1024',
      'name': 'Kundan Set',
      'rate_paise': 62000,
      'weight_mg': null,
      'share_path': 't/p/share.jpg',
      'business_name': 'Shree Jewels',
      'whatsapp_phone': null,
      'watermark_enabled': false,
      'cost_paise': 1, // even if a buggy server sent it, there is nowhere to put it
    });
    expect(p.rate, const Money.paise(62000));
    expect(p.watermark, isFalse);
  });

  testWidgets('watermark is drawn on the photo and re-encoded as JPEG', (tester) async {
    final source = img.encodeJpg(img.Image(width: 320, height: 240));
    final stamped = await tester.runAsync(() => composeShareImage(source, watermark: 'શ્રી જ્વેલ્સ'));
    final decoded = img.decodeJpg(stamped!)!;
    expect(decoded.width, 320);
    expect(decoded.height, 240);
    expect(stamped, isNot(source));
    expect(await composeShareImage(source), same(source)); // no watermark → untouched
  });

  testWidgets('share a design from its page: photo + caption', (tester) async {
    final sharer = FakeFileSharer();
    composedWatermarks.clear();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.product(productKundanId));
    await _tapPageShare(tester);
    expect(find.text('Share designs'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Share').last);
    await tester.pumpAndSettle();

    final (files, text) = sharer.shared.single;
    expect(files.single.name, '1024.jpg');
    expect(files.single.mimeType, 'image/jpeg');
    expect(text, contains('₹620 per piece'));
    expect(composedWatermarks, ['Shree Jewels']);
  });

  testWidgets('watermark switched off is respected', (tester) async {
    final sharer = FakeFileSharer();
    composedWatermarks.clear();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.product(productKundanId));
    await _tapPageShare(tester);
    await tester.tap(find.text('Business name on photos'));
    await tester.tap(find.text('Show rate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Share').last);
    await tester.pumpAndSettle();
    expect(composedWatermarks, [null]);
    expect(sharer.shared.single.$2, isNot(contains('₹')));
  });

  testWidgets('Navo Maal: select several designs and share them in one go', (tester) async {
    final sharer = FakeFileSharer();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.navoMaal);
    await tester.tap(find.text('Select to share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kundan Set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Share').last);
    await tester.pumpAndSettle();
    expect(sharer.shared.single.$1.single.name, '1024.jpg');
  });

  testWidgets('a design without photos is sent as text and the user is told', (tester) async {
    final sharer = FakeFileSharer();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.product(productJhumkaId));
    await _tapPageShare(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Share').last);
    await tester.pumpAndSettle();
    expect(sharer.shared.single.$1, isEmpty);
    expect(sharer.shared.single.$2, contains('1025 · Jhumka'));
    expect(find.text('These designs have no photos yet; sending text only.'), findsOneWidget);
  });

  test('order summary for the customer never includes the internal note', () {
    final o = OrderDetail(
      id: 'o1',
      orderNo: 1045,
      status: OrderStatus.confirmed,
      totalQty: 12,
      total: const Money.paise(744000),
      createdAt: DateTime.utc(2026, 9, 30, 11),
      note: 'Customer pays late — be careful',
      createdByName: 'Maheshbhai',
      customer: const OrderCustomer(id: 'c1', name: 'Patel Kundan Stores'),
      items: const [
        OrderLine(
          productId: 'p1',
          designNo: '1024',
          name: 'Kundan Set',
          rate: Money.paise(62000),
          qty: 12,
          amount: Money.paise(744000),
        ),
      ],
    );
    final text = orderShareText(AppLocalizationsEn(), o, 'en', 'Shree Jewels');
    expect(text, contains('1024 · Kundan Set — 12 × ₹620 = ₹7,440'));
    expect(text, contains('Total ₹7,440'));
    expect(text, isNot(contains('careful')));
    expect(text, isNot(contains('Maheshbhai')));
  });

  testWidgets('order and receipt can be shared from their screens', (tester) async {
    final sharer = FakeFileSharer();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.orderDetail(orderFirstId));
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    expect(sharer.shared.single.$2, startsWith('Order #1045'));

    await _go(tester, AppRoutes.receipt(paymentFirstId));
    await tester.tap(find.text('Share receipt photo'));
    await tester.pumpAndSettle();
    expect(sharer.shared.last.$1.single.name, 'receipt-7.png');
  });
}
