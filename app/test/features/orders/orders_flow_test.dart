import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/orders/orders.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

Future<void> _pickPatel(WidgetTester tester) async {
  await tester.tap(find.text('Choose customer').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Patel Kundan Stores'));
  await tester.pumpAndSettle();
}

Future<void> _place(WidgetTester tester) async {
  await tester.tap(find.text('Place order'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Maal "+" adds a design; the order is placed from the cart', (tester) async {
    final orders = FakeOrdersRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      orders: orders,
    );
    await tester.tap(find.text('Maal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add').first);
    await tester.pumpAndSettle();
    expect(find.text('Added to order'), findsOneWidget);
    await tester.tap(find.text('Open order'));
    await tester.pumpAndSettle();

    expect(find.text('1024'), findsOneWidget);
    await _pickPatel(tester);
    expect(find.text('Patel Kundan Stores'), findsOneWidget);
    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();
    expect(find.text('₹1,240'), findsWidgets);

    await _place(tester);
    expect(find.text('Order #1046 placed'), findsOneWidget);
    final call = orders.placeCalls.single;
    expect(call.customerId, customerPatelId);
    expect(call.lines.single.qty, 2);
    expect(call.lines.single.expectedRate, const Money.paise(62000));

    await tester.tap(find.text('View order'));
    await tester.pumpAndSettle();
    expect(find.text('Order #1046'), findsOneWidget);
    expect(find.text('2 × ₹620'), findsOneWidget);
  });

  testWidgets('quick order by design number, with clear errors', (tester) async {
    final orders = FakeOrdersRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      orders: orders,
    );
    await tester.tap(find.text('Order').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick order'));
    await tester.pumpAndSettle();
    await _pickPatel(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Design no.'), '9999');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(find.text('No design 9999'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Design no.'), '1025');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(find.text('1025 is not available'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Design no.'), '1024');
    await tester.enterText(find.widgetWithText(TextField, 'Qty'), '24');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(find.text('₹14,880'), findsWidgets);
    expect(find.text('24 pcs · 1,008 g'), findsOneWidget);

    await _place(tester);
    expect(orders.placeCalls.single.lines.single.qty, 24);
  });

  testWidgets('payment with the order is sent with the order', (tester) async {
    final orders = FakeOrdersRepository();
    final carts = MemoryCartStore()
      ..drafts['t-a/u-owner'] = const CartDraft(
        requestId: 'r1',
        customerId: customerPatelId,
        customerName: 'Patel Kundan Stores',
        lines: [
          CartLine(productId: productKundanId, designNo: '1024', name: 'Kundan Set', rate: Money.paise(62000), qty: 2),
        ],
      );
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      orders: orders,
      carts: carts,
    );
    await _go(tester, AppRoutes.cart());
    await tester.ensureVisible(find.text('Payment received now'));
    await tester.tap(find.text('Payment received now'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('UPI'));
    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '1000');
    await _place(tester);
    final payment = orders.placeCalls.single.payment!;
    expect(payment.amount, const Money.paise(100000));
    expect(payment.mode, PaymentMode.upi);
  });

  testWidgets('staff without payments.record cannot take payment with an order', (tester) async {
    final carts = MemoryCartStore()
      ..drafts['t-a/u-staff'] = const CartDraft(
        requestId: 'r1',
        customerId: customerPatelId,
        customerName: 'Patel Kundan Stores',
        lines: [
          CartLine(productId: productKundanId, designNo: '1024', name: 'Kundan Set', rate: Money.paise(62000), qty: 1),
        ],
      );
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      carts: carts,
    );
    await _go(tester, AppRoutes.cart());
    expect(find.text('Payment received now'), findsNothing);
  });

  testWidgets('a rate change is explained and the cart shows today\'s rate', (tester) async {
    final orders = FakeOrdersRepository()
      ..placeErrors.add(
        const AppFailure(
          FailureKind.rateChanged,
          details: [
            {'product_id': productKundanId, 'rate_paise': 64000},
          ],
        ),
      );
    final carts = MemoryCartStore()
      ..drafts['t-a/u-owner'] = const CartDraft(
        requestId: 'r1',
        customerId: customerPatelId,
        customerName: 'Patel Kundan Stores',
        lines: [
          CartLine(productId: productKundanId, designNo: '1024', name: 'Kundan Set', rate: Money.paise(62000), qty: 1),
        ],
      );
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      orders: orders,
      carts: carts,
    );
    await _go(tester, AppRoutes.cart());
    await _place(tester);
    expect(find.text('Rates changed'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('₹640'), findsWidgets);
    await _place(tester);
    expect(orders.placeCalls.last.lines.single.expectedRate, const Money.paise(64000));
    expect(find.text('Order #1046 placed'), findsOneWidget);
  });

  testWidgets('"Order Karo" on a customer starts their order', (tester) async {
    await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
    await _go(tester, AppRoutes.customerDetail(customerShahId));
    await tester.tap(find.text('Order Karo'));
    await tester.pumpAndSettle();
    expect(find.text('Shah Imitation'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
  });

  group('orders tab and detail', () {
    testWidgets('pending orders list opens the order', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await tester.tap(find.text('Order').last);
      await tester.pumpAndSettle();
      expect(find.text('Patel Kundan Stores'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      await tester.tap(find.text('Patel Kundan Stores'));
      await tester.pumpAndSettle();
      expect(find.text('Order #1045'), findsOneWidget);
      expect(find.textContaining('By Maheshbhai'), findsOneWidget);
    });

    testWidgets('manager moves the order forward', (tester) async {
      final orders = FakeOrdersRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        orders: orders,
      );
      await _go(tester, AppRoutes.orderDetail(orderFirstId));
      await tester.ensureVisible(find.text('Mark Ready'));
      await tester.tap(find.text('Mark Ready'));
      await tester.pumpAndSettle();
      expect(orders.transitions.single, (orderFirstId, OrderStatus.ready));
      expect(find.text('Mark Completed'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000)); // back to the top
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Mark Completed'), findsOneWidget);
    });

    testWidgets('cancel asks first and states what happens to Baki', (tester) async {
      final orders = FakeOrdersRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        orders: orders,
      );
      await _go(tester, AppRoutes.orderDetail(orderFirstId));
      await tester.ensureVisible(find.text('Cancel order'));
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The order amount will be removed from Baki. Payments already received stay as the customer\'s credit.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep order'));
      await tester.pumpAndSettle();
      expect(orders.cancels, isEmpty);

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Reason (optional)'), 'Customer changed mind');
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel order'));
      await tester.pumpAndSettle();
      expect(orders.cancels.single, (orderFirstId, 'Customer changed mind'));
      expect(find.text('Cancelled: Customer changed mind'), findsOneWidget);
    });

    testWidgets('staff without orders.manage cannot change status or cancel', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
      await _go(tester, AppRoutes.orderDetail(orderFirstId));
      expect(find.text('Mark Ready'), findsNothing);
      expect(find.text('Cancel order'), findsNothing);
      expect(find.text('Fari Order'), findsOneWidget); // staff can create orders
    });

    testWidgets('Fari Order fills the cart with the same designs at today\'s rates', (tester) async {
      final orders = FakeOrdersRepository()..special[customerPatelId] = {productKundanId: 60000};
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        orders: orders,
      );
      await _go(tester, AppRoutes.orderDetail(orderFirstId));
      await tester.ensureVisible(find.text('Fari Order'));
      await tester.tap(find.text('Fari Order'));
      await tester.pumpAndSettle();
      expect(find.text('Patel Kundan Stores'), findsOneWidget);
      expect(find.text('₹7,200'), findsWidgets); // 12 × ₹600 today
      await _place(tester);
      expect(orders.placeCalls.single.reorderOf, orderFirstId);
      expect(orders.placeCalls.single.lines.single.qty, 12);
    });
  });
}
