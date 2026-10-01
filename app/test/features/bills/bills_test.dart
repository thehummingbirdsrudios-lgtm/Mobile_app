import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/bills/bills.dart';
import 'package:vepari/features/bills/data/remote/bills_api.dart';
import 'package:vepari/features/orders/domain/orders.dart' show OrderBillRef;
import 'package:vepari/features/orders/orders.dart';

import '../../support/fakes.dart';
import '../../support/pdf_inspector.dart';
import '../../support/test_app.dart';

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

OrderDetail _withBill(OrderDetail o) => OrderDetail(
  id: o.id,
  orderNo: o.orderNo,
  status: o.status,
  totalQty: o.totalQty,
  total: o.total,
  createdAt: o.createdAt,
  customer: o.customer,
  items: o.items,
  bill: OrderBillRef(id: billFirstId, billNo: 12, issuedAt: DateTime.utc(2026, 10)),
);

void main() {
  test('bill payload decodes with business snapshot and items', () {
    final b = billDocumentFromJson({
      'bill_no': 12,
      'issued_at': '2026-10-01T10:00:00Z',
      'order_no': 1045,
      'order_status': 'confirmed',
      'customer_name': 'Patel',
      'customer_phone': null,
      'business': {'business_name': 'Shree Jewels', 'gstin': '24ABCDE1234F1Z5', 'watermark_enabled': true},
      'total_qty': 12,
      'total_paise': 744000,
      'total_weight_mg': null,
      'paid_paise': 0,
      'balance_after_paise': 744000,
      'items': [
        {'design_no': '1024', 'name': 'Kundan Set', 'qty': 12, 'rate_paise': 62000, 'amount_paise': 744000},
      ],
    });
    expect(b.business.gstin, '24ABCDE1234F1Z5');
    expect(b.business.watermark, isTrue);
    expect(b.items.single.amount, const Money.paise(744000));
  });

  testWidgets('owner makes a bill from the order and sees it', (tester) async {
    final bills = FakeBillsRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      bills: bills,
    );
    await _go(tester, AppRoutes.orderDetail(orderFirstId));
    await tester.ensureVisible(find.text('Make bill'));
    await tester.tap(find.text('Make bill'));
    await tester.pumpAndSettle();
    expect(bills.issued, [orderFirstId]);
    expect(find.text('Bill #12'), findsWidgets);
    expect(find.text('Patel Kundan Stores'), findsOneWidget);
    expect(find.text('Soni Bazar, Rajkot'), findsOneWidget);
    expect(find.text('₹7,440'), findsWidgets);
    expect(find.text('₹53,200'), findsOneWidget); // Baki after this bill
    expect(find.text('Thank you'), findsOneWidget);
  });

  testWidgets('an order with a bill links to it; staff without bills.issue cannot make one', (tester) async {
    final orders = FakeOrdersRepository(orders: [_withBill(sampleOrders().first)]);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      orders: orders,
    );
    await _go(tester, AppRoutes.orderDetail(orderFirstId));
    expect(find.text('Make bill'), findsNothing);
    await tester.ensureVisible(find.text('View bill'));
    await tester.tap(find.text('View bill'));
    await tester.pumpAndSettle();
    expect(find.text('Send bill photo'), findsOneWidget);
  });

  testWidgets('staff without bills.issue see no Make bill', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
    await _go(tester, AppRoutes.orderDetail(orderFirstId));
    expect(find.text('Make bill'), findsNothing);
  });

  testWidgets('send bill as photo and as PDF', (tester) async {
    final sharer = FakeFileSharer();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.bill(billFirstId));
    await tester.tap(find.text('Send bill photo'));
    await tester.pumpAndSettle();
    final (files, text) = sharer.shared.single;
    expect(files.single.name, 'bill-12.png');
    expect(files.single.mimeType, 'image/png');
    expect(text, 'Bill #12 from Shree Jewels');

    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();
    final pdf = sharer.shared.last.$1.single;
    expect(pdf.name, 'bill-12.pdf');
    expect(pdf.mimeType, 'application/pdf');
    final inside = PdfInspection(pdf.bytes);
    expect(inside.isPdf, isTrue);
    // The line's product photo is really inside the PDF.
    expect(inside.images.values.where((i) => i.filter == 'DCTDecode'), hasLength(1));
    expect(inside.imagesDrawn, isNotEmpty);
  });

  testWidgets('sharing unavailable is explained', (tester) async {
    final sharer = FakeFileSharer()..available = false;
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      sharer: sharer,
    );
    await _go(tester, AppRoutes.bill(billFirstId));
    await tester.tap(find.text('Send bill photo'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open sharing on this phone.'), findsOneWidget);
  });

  testWidgets('huge amounts and long names never overflow the bill', (tester) async {
    final bills = FakeBillsRepository()
      ..documents[billFirstId] = BillDocument(
        billNo: 99999,
        issuedAt: DateTime.utc(2026, 10),
        orderNo: 123456,
        customerName: 'શ્રી રાધે કૃષ્ણ ઇમિટેશન જ્વેલરી એન્ડ ફેન્સી સ્ટોર્સ, સોની બજાર',
        business: const BillBusiness(name: 'Shree Jewels and Imitation Ornaments Wholesale Rajkot'),
        totalQty: 100000,
        total: const Money.paise(999999900000000 ~/ 100),
        paid: Money.zero,
        balanceAfter: const Money.paise(999999900000000 ~/ 100),
        items: const [
          BillItem(
            designNo: 'KUNDAN-NECKLACE-2026-XL',
            name: 'Very long design name that keeps going and going for testing',
            qty: 100000,
            rate: Money.paise(99999999),
            amount: Money.paise(9999999900000),
          ),
        ],
      );
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      bills: bills,
      size: const Size(320, 700),
    );
    await _go(tester, AppRoutes.bill(billFirstId));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bill renders in Gujarati without overflow at 320dp', (tester) async {
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      locale: const Locale('gu'),
      size: const Size(320, 640),
    );
    await _go(tester, AppRoutes.bill(billFirstId));
    expect(find.text('બિલ #12'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
