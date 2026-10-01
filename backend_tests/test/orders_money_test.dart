// Orders, payments, Hisaab (ledger) and bills: server-authoritative totals,
// idempotency under retries and concurrency, state machine, history
// stability and exact balance reconciliation.
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late TenantFixture b;
  late Actor owner;
  late Actor staffFull;
  late Actor staffMin;

  Future<Map<String, dynamic>> createOrder(
    Actor actor,
    String customer,
    String items, {
    String? requestId,
    String? reorderOf,
    String? payment,
  }) {
    return actor.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid, null, @ro::uuid, @pay::jsonb)', {
      'c': customer,
      'items': items,
      'r': requestId ?? TestDb.newId(),
      'ro': reorderOf,
      'pay': payment,
    });
  }

  Future<Map<String, dynamic>> pay(Actor actor, String customer, int paise, {String? requestId, String mode = 'upi'}) {
    return actor.json('select public.record_payment(@c::uuid, @a::bigint, @m::public.payment_mode, @r::uuid)', {
      'c': customer,
      'a': paise,
      'm': mode,
      'r': requestId ?? TestDb.newId(),
    });
  }

  Future<int> balance(String customer) async {
    final r = await db.admin.execute(
      'select balance_paise from public.customer_balances where customer_id = \$1',
      parameters: [customer],
    );
    return r.first.first! as int;
  }

  Future<int> ledgerSum(String customer) async {
    final r = await db.admin.execute(
      'select coalesce(sum(amount_paise), 0)::bigint from public.ledger_entries where customer_id = \$1',
      parameters: [customer],
    );
    return r.first.first! as int;
  }

  setUpAll(() async {
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    b = world[1];
    owner = await db.actor(a.ownerId);
    staffFull = await db.actor(a.staffFullId);
    staffMin = await db.actor(a.staffMinId);
  });

  tearDownAll(() => db.dispose());

  group('create_order', () {
    test('server computes totals with customer-specific rates', () async {
      final order = await createOrder(staffFull, a.rajesh, orderItems([(a.kundan, 20), (a.jhumka, 10)]));
      // 1024 @ ₹600 (Rajesh override) × 20 + 1025 @ ₹320 × 10
      expect(order['total_paise'], 20 * 60000 + 10 * 32000);
      expect(order['total_qty'], 30);
      expect(order['total_weight_mg'], 20 * 42000 + 10 * 18000);
      expect(order['status'], 'confirmed');
      expect(order['replayed'], isFalse);

      final items = await owner.query(
        'select design_no, rate_paise, qty, amount_paise, thumb_path from public.order_items '
        'where order_id = @o::uuid order by line_no',
        {'o': order['order_id']},
      );
      expect(items.map((r) => [r[0], r[1], r[2], r[3]]), [
        ['1024', 60000, 20, 1200000],
        ['1025', 32000, 10, 320000],
      ]);
      expect(items.first[4], '${a.tenantId}/products/1024/thumb.jpg');
    });

    test('duplicate product lines are merged', () async {
      final order = await createOrder(owner, a.suresh, orderItems([(a.kundan, 2), (a.kundan, 3)]));
      expect(order['total_qty'], 5);
      expect(order['total_paise'], 5 * 62000);
      expect(
        await owner.count('select 1 from public.order_items where order_id = @o::uuid', {'o': order['order_id']}),
        1,
      );
    });

    test('rejects empty, invalid and oversized input', () async {
      await expectLater(() => createOrder(owner, a.rajesh, '[]'), throwsDbError('order_empty'));
      await expectLater(
        () => createOrder(owner, a.rajesh, orderItems([(a.kundan, 0)])),
        throwsDbError('invalid_quantity'),
      );
      await expectLater(
        () => createOrder(owner, a.rajesh, orderItems([(a.kundan, -3)])),
        throwsDbError('invalid_quantity'),
      );
      await expectLater(
        () => createOrder(owner, a.rajesh, orderItems([(a.kundan, 100001)])),
        throwsDbError('invalid_quantity'),
      );
      await expectLater(
        () => createOrder(owner, a.rajesh, '[{"product_id":"${a.kundan}","qty":"abc"}]'),
        throwsDbError('invalid_request'),
      );
      await expectLater(
        () => createOrder(owner, a.rajesh, '[{"product_id":"nope","qty":1}]'),
        throwsDbError('invalid_request'),
      );
      await expectLater(
        () => createOrder(owner, a.rajesh, '[{"product_id":"${a.kundan}","qty":1.5}]'),
        throwsDbError('invalid_request'),
      );
      final tooMany = '[${List.filled(201, '{"product_id":"${a.kundan}","qty":1}').join(',')}]';
      await expectLater(() => createOrder(owner, a.rajesh, tooMany), throwsDbError('order_too_large'));
    });

    test('rejects archived and unavailable designs', () async {
      await expectLater(
        () => createOrder(owner, a.rajesh, orderItems([(a.archived, 1)])),
        throwsDbError('product_unavailable'),
      );
      await expectLater(
        () => createOrder(owner, a.rajesh, orderItems([(a.unavailable, 1)])),
        throwsDbError('product_unavailable'),
      );
    });

    test('rate changed since the draft is rejected, not silently repriced', () async {
      await expectLater(
        () => createOrder(owner, a.rajesh, orderItems([(a.kundan, 1)], expectedRates: {a.kundan: 62000})),
        throwsDbError('rate_changed'),
      );
      final ok = await createOrder(owner, a.rajesh, orderItems([(a.kundan, 1)], expectedRates: {a.kundan: 60000}));
      expect(ok['total_paise'], 60000);
    });

    test('archived customer cannot receive new orders', () async {
      final id = await db.admin.execute(
        "insert into public.customers (tenant_id, name, archived_at) values (\$1, 'Gone', now()) returning id",
        parameters: [a.tenantId],
      );
      await expectLater(
        () => createOrder(owner, id.first.first! as String, orderItems([(a.kundan, 1)])),
        throwsDbError('customer_inactive'),
      );
    });

    test('staff without orders.create is denied', () async {
      await expectLater(
        () => createOrder(staffMin, a.rajesh, orderItems([(a.kundan, 1)])),
        throwsDbError('permission_denied'),
      );
    });

    test('clients cannot write orders, items or ledger directly', () async {
      await expectLater(
        () => owner.query(
          'insert into public.orders (order_no, customer_id, total_qty, total_paise, client_request_id, created_by) '
          'values (1, @c::uuid, 1, 1, gen_random_uuid(), @u::uuid)',
          {'c': a.rajesh, 'u': a.ownerId},
        ),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => owner.query("update public.order_items set rate_paise = 1 where tenant_id = @t::uuid", {'t': a.tenantId}),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => owner.query('update public.customer_balances set balance_paise = 0'),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('order numbers are sequential per tenant and independent across tenants', () async {
      final ownerB = await db.actor(b.ownerId);
      final b1 = await createOrder(ownerB, b.rajesh, orderItems([(b.kundan, 1)]));
      final a1 = await createOrder(owner, a.suresh, orderItems([(a.jhumka, 1)]));
      final a2 = await createOrder(owner, a.suresh, orderItems([(a.jhumka, 1)]));
      expect(a2['order_no'], (a1['order_no'] as int) + 1);
      expect(b1['order_no'], 1);
    });
  });

  group('idempotency', () {
    test('a retried create_order returns the first order and posts Baki once', () async {
      final requestId = TestDb.newId();
      final before = await balance(a.suresh);
      final first = await createOrder(owner, a.suresh, orderItems([(a.haar, 2)]), requestId: requestId);
      final retry = await createOrder(owner, a.suresh, orderItems([(a.haar, 2)]), requestId: requestId);
      expect(retry['order_id'], first['order_id']);
      expect(retry['replayed'], isTrue);
      expect(await balance(a.suresh), before + 300000);
    });

    test('10 concurrent submissions with one request id create exactly one order', () async {
      final requestId = TestDb.newId();
      final actors = [for (var i = 0; i < 10; i++) await db.actor(a.staffFullId)];
      final results = await Future.wait(
        actors.map((x) => createOrder(x, a.rajesh, orderItems([(a.jhumka, 1)]), requestId: requestId)),
      );
      expect(results.map((r) => r['order_id']).toSet(), hasLength(1));
      expect(results.where((r) => r['replayed'] == false), hasLength(1));
      final count = await db.admin.execute(
        'select count(*) from public.orders where client_request_id = \$1',
        parameters: [requestId],
      );
      expect(count.first.first, 1);
    });

    test('10 concurrent payment retries record exactly one payment', () async {
      final requestId = TestDb.newId();
      final before = await balance(a.rajesh);
      final actors = [for (var i = 0; i < 10; i++) await db.actor(a.staffFullId)];
      final results = await Future.wait(actors.map((x) => pay(x, a.rajesh, 5000, requestId: requestId)));
      expect(results.map((r) => r['payment_id']).toSet(), hasLength(1));
      expect(await balance(a.rajesh), before - 5000);
    });

    test('concurrent distinct payments keep old/new Baki consistent', () async {
      final actors = [for (var i = 0; i < 8; i++) await db.actor(a.staffFullId)];
      final before = await balance(a.suresh);
      final results = await Future.wait(actors.map((x) => pay(x, a.suresh, 1000)));
      expect(await balance(a.suresh), before - 8000);
      // Receipts chain: each payment's "after" is someone's "before".
      final afters = results.map((r) => r['balance_after_paise'] as int).toSet();
      final befores = results.map((r) => r['balance_before_paise'] as int).toSet();
      expect(befores.contains(before), isTrue);
      expect(afters.contains(before - 8000), isTrue);
      expect(befores.difference({before}), afters.difference({before - 8000}));
    });
  });

  group('review regressions', () {
    test('a replayed order returns the payment taken with it', () async {
      final requestId = TestDb.newId();
      const pay = '{"amount_paise": 100000, "mode": "cash"}';
      final first = await createOrder(owner, a.suresh, orderItems([(a.jhumka, 5)]), requestId: requestId, payment: pay);
      final retry = await createOrder(owner, a.suresh, orderItems([(a.jhumka, 5)]), requestId: requestId, payment: pay);
      expect(retry['replayed'], isTrue);
      expect(retry['payment']['payment_id'], first['payment']['payment_id']);
      expect(retry['payment']['replayed'], isTrue);
    });

    test('order lines always sum to the order total and its ledger entry', () async {
      final drift = await db.admin.execute('''
        select o.id from public.orders o
          join public.ledger_entries l on l.order_id = o.id and l.kind = 'order'
         where o.total_paise <> (select sum(i.amount_paise) from public.order_items i where i.order_id = o.id)
            or l.amount_paise <> o.total_paise''');
      expect(drift, isEmpty);
    });

    test('concurrent opening balances: exactly one wins, the other gets opening_exists', () async {
      final row = await db.admin.execute(
        "insert into public.customers (tenant_id, name) values (\$1, 'Opening Race') returning id",
        parameters: [a.tenantId],
      );
      final customer = row.first.first! as String;
      final actors = [for (var i = 0; i < 5; i++) await db.actor(a.ownerId)];
      final outcomes = await Future.wait(
        actors.map(
          (x) => x
              .query("select public.record_adjustment(@c::uuid, 'opening', 10000, @r::uuid)", {
                'c': customer,
                'r': TestDb.newId(),
              })
              .then((_) => 'ok', onError: (Object e) => e is ServerException ? e.message : '$e'),
        ),
      );
      expect(outcomes.where((o) => o == 'ok'), hasLength(1));
      expect(outcomes.where((o) => o != 'ok'), everyElement('opening_exists'));
      expect(await balance(customer), 10000);
    });
  });

  group('payments', () {
    test('receipt shows old and new Baki', () async {
      final before = await balance(a.rajesh);
      final p = await pay(owner, a.rajesh, 10000, mode: 'cash');
      expect(p['balance_before_paise'], before);
      expect(p['balance_after_paise'], before - 10000);
      expect(p['mode'], 'cash');
    });

    test('rejects zero, negative and absurd amounts', () async {
      await expectLater(() => pay(owner, a.rajesh, 0), throwsDbError('invalid_amount'));
      await expectLater(() => pay(owner, a.rajesh, -500), throwsDbError('invalid_amount'));
      await expectLater(() => pay(owner, a.rajesh, 10000000000001), throwsDbError('invalid_amount'));
      await expectLater(
        () => owner.query("select public.record_payment(@c::uuid, 100, 'bitcoin', @r::uuid)", {
          'c': a.rajesh,
          'r': TestDb.newId(),
        }),
        throwsDbError('22P02'),
      );
    });

    test('payment taken with the order is atomic with it', () async {
      final before = await balance(a.suresh);
      final order = await createOrder(
        owner,
        a.suresh,
        orderItems([(a.kundan, 10)]),
        payment: '{"amount_paise": 200000, "mode": "upi"}',
      );
      expect(order['payment']['amount_paise'], 200000);
      expect(await balance(a.suresh), before + 620000 - 200000);

      // A bad payment rolls back the whole order.
      final requestId = TestDb.newId();
      await expectLater(
        () => createOrder(
          owner,
          a.suresh,
          orderItems([(a.kundan, 1)]),
          requestId: requestId,
          payment: '{"amount_paise": -1, "mode": "upi"}',
        ),
        throwsDbError('invalid_amount'),
      );
      final none = await db.admin.execute(
        'select count(*) from public.orders where client_request_id = \$1',
        parameters: [requestId],
      );
      expect(none.first.first, 0);
    });

    test('staff without payments.record is denied', () async {
      await expectLater(() => pay(staffMin, a.rajesh, 100), throwsDbError('permission_denied'));
    });
  });

  group('order lifecycle', () {
    test('valid transitions succeed, invalid jumps fail', () async {
      final order = await createOrder(owner, a.rajesh, orderItems([(a.jhumka, 1)]));
      final id = order['order_id'];
      Future<Map<String, dynamic>> move(String to) =>
          owner.json('select public.transition_order(@o::uuid, @s::public.order_status)', {'o': id, 's': to});

      expect((await move('processing'))['status'], 'processing');
      await expectLater(() => move('confirmed'), throwsDbError('invalid_transition'));
      expect((await move('ready'))['status'], 'ready');
      expect((await move('ready'))['replayed'], isTrue);
      expect((await move('completed'))['status'], 'completed');
      await expectLater(
        () => owner.query('select public.cancel_order(@o::uuid)', {'o': id}),
        throwsDbError('invalid_transition'),
      );
      await expectLater(() => move('cancelled'), throwsDbError('invalid_request'));
    });

    test('cancel reverses exactly the order amount, once', () async {
      final before = await balance(a.suresh);
      final order = await createOrder(owner, a.suresh, orderItems([(a.haar, 1)]));
      expect(await balance(a.suresh), before + 150000);
      final cancelled = await owner.json("select public.cancel_order(@o::uuid, 'customer ne nathi joitu')", {
        'o': order['order_id'],
      });
      expect(cancelled['status'], 'cancelled');
      final again = await owner.json('select public.cancel_order(@o::uuid)', {'o': order['order_id']});
      expect(again['replayed'], isTrue);
      expect(await balance(a.suresh), before);
    });

    test('staff without orders.manage cannot change status', () async {
      final order = await createOrder(owner, a.rajesh, orderItems([(a.jhumka, 1)]));
      await expectLater(
        () => staffMin.query("select public.transition_order(@o::uuid, 'ready')", {'o': order['order_id']}),
        throwsDbError('permission_denied'),
      );
    });
  });

  group('history and bills', () {
    test('rate changes and archival never alter confirmed orders or bills', () async {
      final order = await createOrder(owner, a.suresh, orderItems([(a.jhumka, 4)]));
      final bill = await owner.json('select public.issue_bill(@o::uuid)', {'o': order['order_id']});
      await owner.query('update public.products set rate_paise = 99900 where id = @p::uuid', {'p': a.jhumka});
      await owner.query(
        "update public.products set status = 'archived', archived_at = now(), name = 'Renamed' where id = @p::uuid",
        {'p': a.jhumka},
      );

      final payload = await owner.json('select public.bill_payload(@b::uuid)', {'b': bill['bill_id']});
      final items = (payload['items'] as List).cast<Map<String, dynamic>>();
      expect(items.single['rate_paise'], 32000);
      expect(items.single['name'], 'Jhumka झुमका');
      expect(payload['total_paise'], 4 * 32000);

      // Restore for other tests.
      await owner.query(
        "update public.products set status = 'active', archived_at = null, rate_paise = 32000, name = 'Jhumka झुमका' "
        'where id = @p::uuid',
        {'p': a.jhumka},
      );
    });

    test('issue_bill is idempotent and matches the authoritative order', () async {
      final order = await createOrder(
        owner,
        a.rajesh,
        orderItems([(a.kundan, 20), (a.jhumka, 10), (a.haar, 5)]),
        payment: '{"amount_paise": 500000, "mode": "cash"}',
      );
      final first = await owner.json('select public.issue_bill(@o::uuid)', {'o': order['order_id']});
      final second = await owner.json('select public.issue_bill(@o::uuid)', {'o': order['order_id']});
      expect(second['bill_id'], first['bill_id']);
      expect(second['replayed'], isTrue);

      final payload = await owner.json('select public.bill_payload(@b::uuid)', {'b': first['bill_id']});
      final items = (payload['items'] as List).cast<Map<String, dynamic>>();
      final itemSum = items.fold<int>(0, (s, i) => s + (i['amount_paise'] as int));
      expect(payload['total_paise'], order['total_paise']);
      expect(itemSum, order['total_paise']);
      expect(payload['total_qty'], 35);
      expect(payload['paid_paise'], 500000);
      expect(payload['balance_after_paise'], await balance(a.rajesh));
    });

    test('cancelled orders cannot be billed', () async {
      final order = await createOrder(owner, a.rajesh, orderItems([(a.jhumka, 1)]));
      await owner.query('select public.cancel_order(@o::uuid)', {'o': order['order_id']});
      await expectLater(
        () => owner.query('select public.issue_bill(@o::uuid)', {'o': order['order_id']}),
        throwsDbError('order_cancelled'),
      );
    });
  });

  group('ledger integrity', () {
    test('ledger rows and payments are immutable, even for the database owner', () async {
      await expectLater(
        () => db.admin.execute('update public.ledger_entries set amount_paise = 1'),
        throwsDbError('immutable_record'),
      );
      await expectLater(() => db.admin.execute('delete from public.payments'), throwsDbError('immutable_record'));
      await expectLater(() => db.admin.execute('delete from public.audit_logs'), throwsDbError('immutable_record'));
    });

    test('adjustments need a note; opening balance is allowed once', () async {
      Future<Map<String, dynamic>> adjust(String kind, int amount, String? note) => owner.json(
        'select public.record_adjustment(@c::uuid, @k::public.ledger_kind, @a::bigint, @r::uuid, @n)',
        {'c': a.suresh, 'k': kind, 'a': amount, 'r': TestDb.newId(), 'n': note},
      );
      await expectLater(() => adjust('adjustment', -500, null), throwsDbError('note_required'));
      await expectLater(() => adjust('payment', -500, 'x'), throwsDbError('invalid_request'));
      await expectLater(() => adjust('adjustment', 0, 'x'), throwsDbError('invalid_amount'));
      await adjust('opening', 25000, null);
      await expectLater(() => adjust('opening', 1000, null), throwsDbError('opening_exists'));
      final r = await adjust('adjustment', -2500, 'Return: 1 piece tutelu');
      expect(r['balance_after_paise'], await balance(a.suresh));
      await expectLater(
        () => staffMin.query("select public.record_adjustment(@c::uuid, 'adjustment', 1, @r::uuid, 'x')", {
          'c': a.suresh,
          'r': TestDb.newId(),
        }),
        throwsDbError('permission_denied'),
      );
    });

    test('random operation sequences: Baki always equals the ledger and an independent model', () async {
      final rnd = Random(20261001);
      final customerRow = await db.admin.execute(
        "insert into public.customers (tenant_id, name) values (\$1, 'Property Test Customer') returning id",
        parameters: [a.tenantId],
      );
      final customer = customerRow.first.first! as String;
      var model = 0;
      final open = <(String, int)>[];

      for (var step = 0; step < 150; step++) {
        final op = rnd.nextInt(4);
        if (op == 0 || op == 1) {
          final qty = rnd.nextInt(50) + 1;
          final o = await createOrder(owner, customer, orderItems([(a.jhumka, qty)]));
          model += qty * 32000;
          open.add((o['order_id'] as String, qty * 32000));
        } else if (op == 2) {
          final amount = rnd.nextInt(500000) + 1;
          await pay(owner, customer, amount);
          model -= amount;
        } else if (open.isNotEmpty) {
          final (id, amount) = open.removeAt(rnd.nextInt(open.length));
          await owner.query('select public.cancel_order(@o::uuid)', {'o': id});
          model -= amount;
        }
      }

      expect(await balance(customer), model);
      expect(await ledgerSum(customer), model);
      final last = await db.admin.execute(
        'select balance_after_paise from public.ledger_entries where customer_id = \$1 '
        'order by created_at desc, id desc limit 1',
        parameters: [customer],
      );
      expect(last.first.first, model);
    });

    test('every customer balance reconciles with its ledger', () async {
      final drift = await db.admin.execute('''
        select b.customer_id
          from public.customer_balances b
          left join (select customer_id, sum(amount_paise) s from public.ledger_entries group by customer_id) l
            on l.customer_id = b.customer_id
         where b.balance_paise <> coalesce(l.s, 0)''');
      expect(drift, isEmpty);
    });
  });

  group('reorder (Fari Order)', () {
    test('preview shows today rate and availability; reorder links the source', () async {
      final source = await createOrder(owner, a.rajesh, orderItems([(a.kundan, 20), (a.jhumka, 10)]));
      await owner.query('update public.products set rate_paise = 33000 where id = @p::uuid', {'p': a.jhumka});
      final preview = await owner.query(
        'select design_no, qty, old_rate_paise, rate_paise, is_orderable from public.reorder_preview(@o::uuid)',
        {'o': source['order_id']},
      );
      expect(preview.map((r) => r.toList()), [
        ['1024', 20, 60000, 60000, true],
        ['1025', 10, 32000, 33000, true],
      ]);
      final again = await createOrder(
        owner,
        a.rajesh,
        orderItems([(a.kundan, 20), (a.jhumka, 12)]),
        reorderOf: source['order_id'] as String,
      );
      expect(again['total_paise'], 20 * 60000 + 12 * 33000);
      await owner.query('update public.products set rate_paise = 32000 where id = @p::uuid', {'p': a.jhumka});
    });

    test('regular maal ranks designs this customer buys repeatedly', () async {
      final rows = await owner.query('select design_no, times_ordered from public.regular_maal(@c::uuid)', {
        'c': a.rajesh,
      });
      expect(rows, isNotEmpty);
      final counts = rows.map((r) => r[1] as int).toList();
      expect(counts, [...counts]..sort((x, y) => y.compareTo(x)));
    });
  });
}
