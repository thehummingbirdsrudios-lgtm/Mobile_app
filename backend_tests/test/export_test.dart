// Owner data export: owner-only, own business only, complete under paging.
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late TenantFixture b;
  late Actor owner;
  late Actor staffFull;
  late String orderId;

  const from = '2000-01-01T00:00:00Z';
  const to = '2100-01-01T00:00:00Z';

  setUpAll(() async {
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    b = world[1];
    owner = await db.actor(a.ownerId);
    staffFull = await db.actor(a.staffFullId);
    final order = await owner.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
      'c': a.rajesh,
      'items': orderItems([(a.kundan, 3), (a.jhumka, 2)]),
      'r': TestDb.newId(),
    });
    orderId = order['order_id'] as String;
    await owner.json("select public.record_payment(@c::uuid, 50000, 'upi', @r::uuid, 'UTR123')", {
      'c': a.rajesh,
      'r': TestDb.newId(),
    });
    // B has the same kind of history; none of it may appear in A's export.
    final ownerB = await db.actor(b.ownerId);
    await ownerB.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
      'c': b.rajesh,
      'items': orderItems([(b.kundan, 9)]),
      'r': TestDb.newId(),
    });
  });

  tearDownAll(() => db.dispose());

  test('only the owner can export — staff with every permission are refused', () async {
    for (final sql in [
      'select * from public.export_customers()',
      'select * from public.export_designs()',
      "select * from public.export_ledger('$from', '$to')",
      "select * from public.export_orders('$from', '$to')",
      "select * from public.export_order_items('$from', '$to')",
    ]) {
      await expectLater(() => staffFull.query(sql), throwsDbError('permission_denied'), reason: sql);
    }
    final anon = await db.actor(null);
    await expectLater(
      () => anon.query('select * from public.export_customers()'),
      throwsDbError(insufficientPrivilege),
    );
  });

  test('customers with Baki, own business only', () async {
    final rows = await owner.query('select name, balance_paise from public.export_customers(null, 1000)');
    final expected = await db.admin.execute(
      'select count(*) from public.customers where tenant_id = \$1',
      parameters: [a.tenantId],
    );
    expect(rows, hasLength(expected.single.first));
    final rajesh = rows.firstWhere((r) => r[0] == 'Rajeshbhai');
    expect(rajesh[1], isNot(0));
  });

  test('designs include the owner\'s cost and supplier', () async {
    final rows = await owner.query(
      'select design_no, cost_paise, supplier_name from public.export_designs(null, 1000) where design_no = \'1024\'',
    );
    expect(rows.single, ['1024', secretCostPaise, secretSupplier]);
  });

  test('ledger: dated entries with order number and payment mode', () async {
    final rows = await owner.query(
      "select kind, amount_paise, order_no, payment_mode, payment_reference from public.export_ledger('$from', '$to', null, null, 1000)",
    );
    expect(rows.map((r) => r[0]), containsAll(['order', 'payment']));
    final payment = rows.firstWhere((r) => r[0] == 'payment');
    expect(payment.sublist(1), [-50000, null, 'upi', 'UTR123']);
    expect(rows.firstWhere((r) => r[0] == 'order')[2], isNotNull);
    // A range in the future is empty.
    expect(await owner.count("select 1 from public.export_ledger('2099-01-01', '2100-01-01')"), 0);
  });

  test('orders and their lines; lines of one order are never split', () async {
    final orders = await owner.query(
      "select id, total_qty from public.export_orders('$from', '$to', null, null, 1000)",
    );
    expect(orders.map((r) => r[0]), contains(orderId));
    final lines = await owner.query(
      "select order_id, line_no, design_no, qty from public.export_order_items('$from', '$to', null, null, 1)",
    );
    final firstOrder = lines.first[0];
    expect(lines.every((r) => r[0] == firstOrder), isTrue, reason: 'p_limit counts orders, not lines');
    final all = await owner.query(
      "select order_id, design_no, qty from public.export_order_items('$from', '$to', null, null, 500) where order_id = @o::uuid",
      {'o': orderId},
    );
    expect(all.map((r) => (r[1], r[2])), [('1024', 3), ('1025', 2)]);
  });

  test('keyset paging returns every row exactly once', () async {
    final seen = <String>[];
    String? after;
    while (true) {
      final page = await owner.query('select id from public.export_customers(@after::uuid, 2)', {'after': after});
      if (page.isEmpty) break;
      seen.addAll(page.map((r) => r.first! as String));
      after = seen.last;
    }
    final total = await owner.count('select 1 from public.export_customers(null, 1000)');
    expect(seen, hasLength(total));
    expect(seen.toSet(), hasLength(total));
  });
}
