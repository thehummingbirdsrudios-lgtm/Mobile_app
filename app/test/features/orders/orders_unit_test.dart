import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/orders/domain/orders.dart';
import 'package:vepari/features/orders/orders.dart';
import 'package:vepari/features/orders/orders_adapters.dart';

import '../../support/fakes.dart';

class _Transport implements RpcTransport {
  final calls = <(String, Map<String, Object?>?)>[];
  Object? response;

  @override
  Future<Object?> rpc(String function, Map<String, Object?>? params) async {
    calls.add((function, params));
    return response;
  }
}

CartLine _line(String id, int rate, int qty, {int? weight, bool orderable = true}) => CartLine(
  productId: id,
  designNo: id,
  name: id,
  rate: Money.paise(rate),
  qty: qty,
  weightMg: weight,
  isOrderable: orderable,
);

void main() {
  group('CartDraft', () {
    test('totals, weight and readiness', () {
      final d = CartDraft(
        requestId: 'r',
        customerId: 'c',
        lines: [_line('a', 62000, 12, weight: 42000), _line('b', 32000, 3, weight: 1500)],
      );
      expect(d.totalQty, 15);
      expect(d.total, const Money.paise(840000));
      expect(d.totalWeightMg, 42000 * 12 + 1500 * 3);
      expect(d.canPlace, isTrue);
    });

    test('a partial weight total is not shown; unavailable lines block placing', () {
      final d = CartDraft(
        requestId: 'r',
        customerId: 'c',
        lines: [_line('a', 100, 1, weight: 5), _line('b', 100, 1, orderable: false)],
      );
      expect(d.totalWeightMg, isNull);
      expect(d.canPlace, isFalse);
    });
  });

  group('PreferencesCartStore', () {
    test('round-trips a draft per identity', () async {
      final prefs = MemoryPreferenceStore();
      final store = PreferencesCartStore(prefs);
      final draft = CartDraft(
        requestId: 'req-1',
        customerId: customerPatelId,
        customerName: 'Patel',
        note: 'urgent',
        reorderOf: orderFirstId,
        lines: [_line(productKundanId, 62000, 12, weight: 42000)],
      );
      await store.write('t-a/u-1', draft);
      final back = store.read('t-a/u-1')!;
      expect(back.requestId, 'req-1');
      expect(back.customerName, 'Patel');
      expect(back.note, 'urgent');
      expect(back.reorderOf, orderFirstId);
      expect(back.lines.single.qty, 12);
      expect(back.lines.single.rate, const Money.paise(62000));
      expect(store.read('t-b/u-2'), isNull);
    });

    test('empty drafts are cleared; corrupt data is dropped', () async {
      final prefs = MemoryPreferenceStore();
      final store = PreferencesCartStore(prefs);
      await store.write('s', const CartDraft(requestId: 'r'));
      expect(store.read('s'), isNull);
      prefs.values['cart.v1.s'] = '{"lines": 5}';
      expect(store.read('s'), isNull);
    });
  });

  group('server error details', () {
    test('rate_changed and product_unavailable details are parsed defensively', () {
      expect(
        rateUpdatesFromDetails([
          {'product_id': 'p1', 'rate_paise': 64000},
          {'product_id': 'p2'},
          'junk',
        ]),
        [(productId: 'p1', rate: const Money.paise(64000))],
      );
      expect(
        unavailableFromDetails([
          {'product_id': 'p1', 'design_no': '1024'},
        ]),
        {'p1'},
      );
      expect(rateUpdatesFromDetails(null), isEmpty);
    });

    test('AppFailure carries decoded details from the server', () {
      final f = AppFailure.from(
        const PostgrestException(
          message: 'rate_changed',
          code: 'P0001',
          details: '[{"product_id":"p1","rate_paise":64000}]',
        ),
      );
      expect(f.kind, FailureKind.rateChanged);
      expect(rateUpdatesFromDetails(f.details).single.rate, const Money.paise(64000));
    });
  });

  test('place sends expected rates, idempotency key, trimmed note and payment', () async {
    final transport = _Transport()
      ..response = {
        'order_id': 'o1',
        'order_no': 1046,
        'customer_id': 'c1',
        'total_qty': 12,
        'total_paise': 744000,
        'replayed': false,
        'payment': {'payment_id': 'p1', 'payment_no': 7, 'amount_paise': 100000, 'balance_after_paise': 644000},
      };
    final repo = OrdersRepositoryImpl(
      OrdersApi(
        ApiClient(
          transport: transport,
          logger: AppLogger(minLevel: LogLevel.error, sinks: const []),
        ),
      ),
    );
    final placed = await repo.place(
      customerId: 'c1',
      lines: const [OrderRequestLine(productId: 'p1', qty: 12, expectedRate: Money.paise(62000))],
      requestId: 'req-1',
      note: '  urgent  ',
      payment: const PaymentInput(amount: Money.paise(100000), mode: PaymentMode.upi, reference: ' '),
    );
    final (fn, params) = transport.calls.single;
    expect(fn, 'create_order');
    expect(params, {
      'p_customer_id': 'c1',
      'p_items': [
        {'product_id': 'p1', 'qty': 12, 'expected_rate_paise': 62000},
      ],
      'p_client_request_id': 'req-1',
      'p_note': 'urgent',
      'p_reorder_of': null,
      'p_payment': {'amount_paise': 100000, 'mode': 'upi', 'reference': null},
    });
    expect(placed.orderNo, 1046);
    expect(placed.payment!.balanceAfter, const Money.paise(644000));
  });

  group('CartController', () {
    late FakeOrdersRepository orders;
    late MemoryCartStore store;
    late ProviderContainer container;
    UserSession session = ownerSession;

    ProviderContainer build() => ProviderContainer(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(orders),
        cartStoreProvider.overrideWithValue(store),
        currentSessionProvider.overrideWith((ref) => session),
      ],
    );

    setUp(() {
      orders = FakeOrdersRepository();
      store = MemoryCartStore();
      session = ownerSession;
      container = build();
      addTearDown(container.dispose);
    });

    CartController cart() => container.read(cartProvider.notifier);
    CartDraft draft() => container.read(cartProvider);

    test('adding the same design twice increments; quick add by design number', () async {
      await cart().addProduct(productKundanId);
      await cart().addProduct(productKundanId, qty: 2);
      expect(draft().lines.single.qty, 3);
      expect(await cart().addDesignNo('9999'), isNull);
      final jhumka = await cart().addDesignNo('1025');
      expect(jhumka!.isOrderable, isFalse); // unavailable designs are not added
      expect(draft().lines, hasLength(1));
    });

    test('choosing a customer re-prices lines at their special rate', () async {
      orders.special[customerPatelId] = {productKundanId: 58000};
      await cart().addProduct(productKundanId, qty: 2);
      expect(draft().lines.single.rate, const Money.paise(62000));
      await cart().selectCustomer(customerPatelId, 'Patel');
      expect(draft().lines.single.rate, const Money.paise(58000));
      expect(draft().lines.single.hasSpecialRate, isTrue);
    });

    test('retrying an unchanged cart reuses the request id; editing makes a new one', () async {
      await cart().selectCustomer(customerPatelId, 'Patel');
      await cart().addProduct(productKundanId, qty: 12);
      orders.placeErrors.add(const AppFailure(FailureKind.timeout));
      await expectLater(cart().place(), throwsA(isA<AppFailure>()));
      final firstId = orders.placeCalls.single.requestId;
      expect(draft().requestId, firstId);
      final placed = await cart().place();
      expect(orders.placeCalls.last.requestId, firstId);
      expect(placed.orderNo, 1046);
      expect(draft().isEmpty, isTrue);
      expect(draft().requestId, isNot(firstId));
    });

    test('placing bumps the business revision so other screens refresh', () async {
      await cart().selectCustomer(customerPatelId, 'Patel');
      await cart().addProduct(productKundanId);
      final before = container.read(businessRevisionProvider);
      await cart().place();
      expect(container.read(businessRevisionProvider), before + 1);
    });

    test('rate_changed updates the cart to server rates and rethrows', () async {
      await cart().selectCustomer(customerPatelId, 'Patel');
      await cart().addProduct(productKundanId, qty: 2);
      orders.placeErrors.add(
        const AppFailure(
          FailureKind.rateChanged,
          details: [
            {'product_id': productKundanId, 'rate_paise': 64000},
          ],
        ),
      );
      await expectLater(cart().place(), throwsA(isA<AppFailure>()));
      expect(draft().lines.single.rate, const Money.paise(64000));
      expect(draft().total, const Money.paise(128000));
    });

    test('product_unavailable marks lines and blocks placing', () async {
      await cart().selectCustomer(customerPatelId, 'Patel');
      await cart().addProduct(productKundanId);
      orders.placeErrors.add(
        const AppFailure(
          FailureKind.productUnavailable,
          details: [
            {'product_id': productKundanId, 'design_no': '1024'},
          ],
        ),
      );
      await expectLater(cart().place(), throwsA(isA<AppFailure>()));
      expect(draft().hasUnavailable, isTrue);
      await expectLater(cart().place(), throwsA(isA<CartException>()));
      expect(orders.placeCalls, hasLength(1));
    });

    test('no customer or empty cart never reaches the server', () async {
      await expectLater(cart().place(), throwsA(isA<CartException>()));
      await cart().selectCustomer(customerPatelId, 'Patel');
      await expectLater(cart().place(), throwsA(isA<CartException>()));
      expect(orders.placeCalls, isEmpty);
    });

    test('the cart is kept per identity', () async {
      await cart().addProduct(productKundanId, qty: 5);
      expect(store.drafts['t-a/u-owner']!.lines.single.qty, 5);
      container.dispose();
      session = staffSession;
      container = build();
      expect(draft().isEmpty, isTrue);
      container.dispose();
      session = ownerSession;
      container = build();
      expect(draft().lines.single.qty, 5);
    });
  });
}
