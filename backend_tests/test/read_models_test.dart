// App read models (migration …0900): correctness, keyset pagination,
// permission-dependent visibility and tenant isolation.
import 'dart:convert';

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
  late Map<String, dynamic> order;
  late String paymentId;

  setUpAll(() async {
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    b = world[1];
    owner = await db.actor(a.ownerId);
    staffFull = await db.actor(a.staffFullId);
    staffMin = await db.actor(a.staffMinId);
    order = await owner.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid, null, null, @pay::jsonb)', {
      'c': a.rajesh,
      'items': orderItems([(a.kundan, 20), (a.jhumka, 10)]),
      'r': TestDb.newId(),
      'pay': '{"amount_paise": 500000, "mode": "upi", "reference": "UPI123"}',
    });
    paymentId = (order['payment'] as Map)['payment_id'] as String;
    await owner.query('select public.issue_bill(@o::uuid)', {'o': order['order_id']});
  });

  tearDownAll(() => db.dispose());

  group('product_detail', () {
    test('owner sees gallery and private data; staff never see private', () async {
      final forOwner = await owner.json('select public.product_detail(@p::uuid)', {'p': a.kundan});
      expect(forOwner['design_no'], '1024');
      expect((forOwner['media'] as List), hasLength(1));
      expect((forOwner['private'] as Map)['supplier_name'], secretSupplier);

      final forStaff = await staffFull.json('select public.product_detail(@p::uuid)', {'p': a.kundan});
      expect(forStaff['private'], isNull);
      expect(jsonEncode(forStaff), isNot(contains(secretSupplier)));
    });

    test('another tenant product is invisible', () async {
      expect(await owner.scalar('select public.product_detail(@p::uuid)', {'p': b.kundan}), isNull);
    });
  });

  group('quote_products', () {
    test('resolves by design number (case-insensitive) with customer-effective rate', () async {
      final rows = await staffMin.query(
        'select input, design_no, rate_paise, default_rate_paise, is_orderable from public.quote_products(@c::uuid, null, @d::text[])',
        {'c': a.rajesh, 'd': '{1024,1025,nope,0999}'},
      );
      final byInput = {for (final r in rows) r[0]: r.toList()};
      expect(byInput['1024'], ['1024', '1024', 60000, 62000, true]);
      expect(byInput['1025']![2], 32000);
      expect(byInput['nope']![1], isNull, reason: 'unknown design is reported, not dropped');
      expect(byInput['0999']![4], isFalse, reason: 'archived design is not orderable');
    });

    test('never resolves another tenant design', () async {
      final rows = await owner.query('select product_id from public.quote_products(null, @ids::uuid[], null)', {
        'ids': '{${b.kundan}}',
      });
      expect(rows.single.first, isNull);
    });
  });

  group('customer_list', () {
    setUpAll(() async {
      for (var i = 0; i < 25; i++) {
        await db.admin.execute(
          Sql.named("insert into public.customers (tenant_id, name, phone) values (@t::uuid, @n, @p)"),
          parameters: {
            't': a.tenantId,
            'n': 'Paging Customer ${i.toString().padLeft(2, '0')}',
            'p': '+9197000000${i.toString().padLeft(2, '0')}',
          },
        );
      }
    });

    test('keyset pagination by name returns every customer exactly once, in order', () async {
      final seen = <String>[];
      String? afterKey;
      String? afterId;
      for (var page = 0; page < 10; page++) {
        final rows = await staffMin.query(
          'select id, name, sort_key from public.customer_list(null, @s, @k, @i::uuid, 7)',
          {'s': 'name', 'k': afterKey, 'i': afterId},
        );
        if (rows.isEmpty) break;
        seen.addAll(rows.map((r) => r[1]! as String));
        afterKey = rows.last[2]! as String;
        afterId = rows.last[0]! as String;
      }
      expect(seen, hasLength(27)); // Rajeshbhai, Sureshbhai + 25
      expect(seen.toSet(), hasLength(27));
      final sorted = [...seen]..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
      expect(seen, sorted);
    });

    test('Baki is hidden without hisaab.view; Baki sort needs it', () async {
      final staffRows = await staffMin.query("select balance_paise from public.customer_list('Rajesh')");
      expect(staffRows.single.first, isNull);
      final ownerRows = await owner.query("select name, balance_paise from public.customer_list(null, 'baki')");
      expect(ownerRows.first.toList(), ['Rajeshbhai', 20 * 60000 + 10 * 32000 - 500000]);
      expect(ownerRows.every((r) => (r[1]! as int) != 0), isTrue);
      final staffBaki = await staffMin.query("select name from public.customer_list(null, 'baki', null, null, 100)");
      expect(staffBaki.length, 27, reason: 'falls back to the name list');
    });

    test('search by name and by phone digits', () async {
      expect(await owner.count("select 1 from public.customer_list('paging customer 1')"), 10);
      expect(
        (await owner.query("select name from public.customer_list('97000 00007')")).single.first,
        'Paging Customer 07',
      );
    });
  });

  group('customer_detail / customer_rates', () {
    test('detail with stats; balance only with hisaab.view', () async {
      final d = await owner.json('select public.customer_detail(@c::uuid)', {'c': a.rajesh});
      expect(d['order_count'], 1);
      expect(d['open_orders'], 1);
      expect(d['special_rates'], 1);
      expect(d['balance_paise'], 20 * 60000 + 10 * 32000 - 500000);
      final s = await staffMin.json('select public.customer_detail(@c::uuid)', {'c': a.rajesh});
      expect(s['balance_paise'], isNull);
    });

    test('special rates list', () async {
      final rows = await staffMin.query(
        'select design_no, default_rate_paise, rate_paise from public.customer_rates(@c::uuid)',
        {'c': a.rajesh},
      );
      expect(rows.single.toList(), ['1024', 62000, 60000]);
    });

    test('other tenant customer is invisible', () async {
      expect(await owner.scalar('select public.customer_detail(@c::uuid)', {'c': b.rajesh}), isNull);
      expect(await owner.count('select 1 from public.customer_rates(@c::uuid)', {'c': b.rajesh}), 0);
    });
  });

  group('orders', () {
    test('order_list scopes and paginates newest first', () async {
      for (var i = 0; i < 4; i++) {
        await owner.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
          'c': a.suresh,
          'items': orderItems([(a.haar, 1)]),
          'r': TestDb.newId(),
        });
      }
      final firstPage = await staffMin.query(
        'select id, order_no, created_at from public.order_list(null, @s, null, null, 3)',
        {'s': 'all'},
      );
      expect(firstPage, hasLength(3));
      final next = await staffMin.query(
        'select order_no from public.order_list(null, @s, @at::timestamptz, @id::uuid, 10)',
        {'s': 'all', 'at': firstPage.last[2], 'id': firstPage.last[0]},
      );
      expect(next, hasLength(2));
      final allNos = [...firstPage.map((r) => r[1]), ...next.map((r) => r[0])];
      expect(allNos, [...allNos]..sort((x, y) => (y! as int).compareTo(x! as int)));
      expect(await staffMin.count("select 1 from public.order_list(@c::uuid, 'pending')", {'c': a.rajesh}), 1);
    });

    test('order_detail: items for all; bill and payments only with permission', () async {
      final o = await owner.json('select public.order_detail(@o::uuid)', {'o': order['order_id']});
      expect((o['items'] as List), hasLength(2));
      expect(o['bill'], isNotNull);
      expect((o['payments'] as List), hasLength(1));
      final s = await staffMin.json('select public.order_detail(@o::uuid)', {'o': order['order_id']});
      expect((s['items'] as List), hasLength(2));
      expect(s['bill'], isNull);
      expect((s['payments'] as List), isEmpty);
      expect(await owner.scalar('select public.order_detail(@o::uuid)', {'o': TestDb.newId()}), isNull);
    });
  });

  group('hisaab', () {
    test('ledger_page needs hisaab.view and paginates', () async {
      final rows = await owner.query(
        'select kind::text, amount_paise, order_no, payment_mode::text from public.ledger_page(@c::uuid)',
        {'c': a.rajesh},
      );
      expect(rows.map((r) => r[0]), containsAll(['order', 'payment']));
      expect(rows.firstWhere((r) => r[0] == 'payment')[3], 'upi');
      expect(await staffMin.count('select 1 from public.ledger_page(@c::uuid)', {'c': a.rajesh}), 0);
    });

    test('payment_receipt is allow-listed and permission-gated', () async {
      final r = await owner.json('select public.payment_receipt(@p::uuid)', {'p': paymentId});
      expect(r['amount_paise'], 500000);
      expect(r['reference'], 'UPI123');
      expect(r['balance_after_paise'], (r['balance_before_paise'] as int) - 500000);
      expect(jsonEncode(r), isNot(contains('private customer note')));
      expect(await staffMin.scalar('select public.payment_receipt(@p::uuid)', {'p': paymentId}), isNull);
    });
  });

  group('owner-only lists', () {
    test('member_list for owner; denied to staff', () async {
      final members = (await owner.scalar('select public.member_list()'))! as List;
      expect(members.map((m) => (m as Map)['role']), containsAll(['owner', 'staff']));
      await expectLater(() => staffFull.query('select public.member_list()'), throwsDbError('permission_denied'));
    });

    test('audit_page for owner with actor names; denied to staff', () async {
      final rows = await owner.query('select action, actor_name from public.audit_page(null, 20)');
      expect(rows.map((r) => r[0]), contains('order.created'));
      await expectLater(() => staffFull.query('select * from public.audit_page()'), throwsDbError('permission_denied'));
    });
  });
}
