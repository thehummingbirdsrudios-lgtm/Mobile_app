// Production-scale query checks (run with tool/db_test.sh --scale).
// Loads 10,000 products, 5,000 customers, 50,000 orders (150,000 items) and
// their ledger for one tenant, plus noise tenants, then measures the hot
// paths AS A REAL OWNER (RLS active) and asserts no sequential scans on
// large tables and bounded latency. Results are written to
// build/perf-results.md for docs/testing/performance-results.md.
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

const _bigTables = {
  'products',
  'customers',
  'orders',
  'order_items',
  'ledger_entries',
  'customer_balances',
  'product_media',
};

void main() {
  final enabled = Platform.environment['VEPARI_SCALE'] == '1';
  // Latency budgets are calibrated on a 4-vCPU dev container; shared CI
  // runners set VEPARI_PERF_BUDGET_FACTOR (e.g. 4). Plan shape (no seq scans)
  // is asserted strictly everywhere.
  final budgetFactor = double.tryParse(Platform.environment['VEPARI_PERF_BUDGET_FACTOR'] ?? '') ?? 1;
  late TestDb db;
  late TenantFixture a;
  late Actor owner;
  late String sampleCustomer;
  final report = StringBuffer();

  Future<void> loadScaleData(
    TenantFixture t, {
    required int products,
    required int customers,
    required int orders,
  }) async {
    final admin = db.admin;
    await admin.execute(
      Sql.named('''
        insert into public.products (tenant_id, design_no, name, rate_paise, weight_mg, published_at)
        select @t::uuid, 'D' || g,
               (array['Kundan Set','Jhumka','Rani Haar','Bangdi','Payal','Mangalsutra','Choker','Nath'])[1 + g % 8] || ' ' || g,
               10000 + (g % 500) * 100, 5000 + g % 50000, now() - (g || ' minutes')::interval
          from generate_series(1, @n::int) g'''),
      parameters: {'t': t.tenantId, 'n': products},
    );
    await admin.execute(
      Sql.named('''
        insert into public.product_media (tenant_id, product_id, kind, status, mime_type, original_path,
          catalogue_path, share_path, thumb_path, width, height, bytes, sha256)
        select p.tenant_id, p.id, 'image', 'ready', 'image/jpeg',
               p.tenant_id || '/products/' || p.id || '/original.jpg',
               p.tenant_id || '/products/' || p.id || '/catalogue.jpg',
               p.tenant_id || '/products/' || p.id || '/share.jpg',
               p.tenant_id || '/products/' || p.id || '/thumb.jpg',
               2000, 2000, 1500000, md5(p.id::text) || md5(p.design_no)
          from public.products p where p.tenant_id = @t::uuid'''),
      parameters: {'t': t.tenantId},
    );
    await admin.execute(
      Sql.named('''
        insert into public.customers (tenant_id, name, city, phone)
        select @t::uuid,
               (array['Rajesh','Suresh','Mahesh','Kalpesh','Nilesh','Hitesh','Paresh','Jignesh','Bhavesh','Dinesh'])[1 + g % 10]
                 || 'bhai ' || (array['Patel','Shah','Soni','Mehta','Desai','Joshi'])[1 + g % 6] || ' ' || g,
               (array['Rajkot','Surat','Ahmedabad','Jamnagar','Mumbai'])[1 + g % 5],
               '+9198' || lpad(g::text, 8, '0')
          from generate_series(1, @n::int) g'''),
      parameters: {'t': t.tenantId, 'n': customers},
    );
    await admin.execute(
      Sql.named('''
        with c as (select array_agg(id order by id) ids from public.customers where tenant_id = @t::uuid)
        insert into public.orders (tenant_id, order_no, customer_id, status, total_qty, total_paise,
                                   client_request_id, created_by, created_at)
        select @t::uuid, 100000 + g, c.ids[1 + g % array_length(c.ids, 1)],
               (array['completed','completed','completed','ready','confirmed','cancelled'])[1 + g % 6]::public.order_status,
               1, 1, gen_random_uuid(), @owner::uuid, now() - (g * 7 || ' minutes')::interval
          from generate_series(1, @n::int) g, c'''),
      parameters: {'t': t.tenantId, 'n': orders, 'owner': t.ownerId},
    );
    await admin.execute(
      Sql.named('''
        with p as (select array_agg(id order by id) ids from public.products where tenant_id = @t::uuid),
             o as (select id, customer_id, order_no from public.orders where tenant_id = @t::uuid and order_no > 100000)
        insert into public.order_items (tenant_id, order_id, customer_id, line_no, product_id, design_no,
                                        product_name, thumb_path, rate_paise, qty, amount_paise, weight_mg)
        select @t::uuid, o.id, o.customer_id, k, pr.id, pr.design_no, pr.name, null,
               pr.rate_paise, 1 + (o.order_no + k) % 20, pr.rate_paise * (1 + (o.order_no + k) % 20), pr.weight_mg
          from o
          cross join generate_series(1, 3) k
          cross join p
          join public.products pr on pr.tenant_id = @t::uuid
                                  and pr.id = p.ids[1 + ((o.order_no * 7 + k * 13) % array_length(p.ids, 1))]'''),
      parameters: {'t': t.tenantId},
    );
    await admin.execute(
      Sql.named('''
        update public.orders o set total_qty = s.q, total_paise = s.a
          from (select order_id, sum(qty) q, sum(amount_paise) a from public.order_items
                 where tenant_id = @t::uuid group by order_id) s
         where o.tenant_id = @t::uuid and o.id = s.order_id'''),
      parameters: {'t': t.tenantId},
    );
    await admin.execute(
      Sql.named('''
        insert into public.ledger_entries (tenant_id, customer_id, kind, amount_paise, balance_after_paise,
                                           order_id, created_by, created_at)
        select @t::uuid, o.customer_id, 'order', o.total_paise,
               sum(o.total_paise) over (partition by o.customer_id order by o.created_at, o.id),
               o.id, o.created_by, o.created_at
          from public.orders o where o.tenant_id = @t::uuid and o.order_no > 100000'''),
      parameters: {'t': t.tenantId},
    );
    await admin.execute(
      Sql.named('''
        update public.customer_balances b set balance_paise = s.total, last_activity_at = now()
          from (select customer_id, sum(amount_paise) total from public.ledger_entries
                 where tenant_id = @t::uuid group by customer_id) s
         where b.tenant_id = @t::uuid and b.customer_id = s.customer_id'''),
      parameters: {'t': t.tenantId},
    );
    await admin.execute(
      Sql.named(
        "update public.tenant_counters set next_value = 200000 where tenant_id = @t::uuid and counter = 'order'",
      ),
      parameters: {'t': t.tenantId},
    );
  }

  /// Runs EXPLAIN ANALYZE as the owner; returns (executionMs, seqScannedBigTables).
  Future<(double, Set<String>)> explain(String sql, [Map<String, Object?> params = const {}]) async {
    final result = await owner.query('explain (analyze, buffers, format json) $sql', params);
    final raw = result.first.first;
    final parsed = (raw is String ? jsonDecode(raw) : raw) as List;
    final top = Map<String, dynamic>.from(parsed.first as Map);
    final seq = <String>{};
    void walk(Map<String, dynamic> node) {
      if (node['Node Type'] == 'Seq Scan' && _bigTables.contains(node['Relation Name'])) {
        seq.add(node['Relation Name'] as String);
      }
      for (final child in (node['Plans'] as List? ?? const [])) {
        walk(Map<String, dynamic>.from(child as Map));
      }
    }

    walk(Map<String, dynamic>.from(top['Plan'] as Map));
    return ((top['Execution Time'] as num).toDouble(), seq);
  }

  /// Median wall-clock latency of an RPC call as seen by the client.
  Future<double> medianMs(Future<void> Function() call, {int runs = 7}) async {
    final samples = <double>[];
    for (var i = 0; i < runs; i++) {
      final sw = Stopwatch()..start();
      await call();
      samples.add(sw.elapsedMicroseconds / 1000);
    }
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  setUpAll(() async {
    if (!enabled) return;
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    final sw = Stopwatch()..start();
    await loadScaleData(a, products: 10000, customers: 5000, orders: 50000);
    await loadScaleData(world[1], products: 3000, customers: 1000, orders: 10000);
    await loadScaleData(world[2], products: 3000, customers: 1000, orders: 10000);
    await db.admin.execute('analyze');
    owner = await db.actor(a.ownerId);
    final busiest = await db.admin.execute(
      'select customer_id from public.orders where tenant_id = \$1 group by customer_id order by count(*) desc limit 1',
      parameters: [a.tenantId],
    );
    sampleCustomer = busiest.first.first! as String;
    final counts = await db.admin.execute('''
      select (select count(*) from public.products), (select count(*) from public.customers),
             (select count(*) from public.orders), (select count(*) from public.order_items),
             (select count(*) from public.ledger_entries), (select count(*) from public.product_media)''');
    final c = counts.first;
    report
      ..writeln('# Scale run (${DateTime.now().toUtc().toIso8601String()})')
      ..writeln()
      ..writeln(
        'Data load: ${sw.elapsed.inSeconds}s. Totals across 3 tenants — products ${c[0]}, customers ${c[1]}, '
        'orders ${c[2]}, order_items ${c[3]}, ledger_entries ${c[4]}, product_media ${c[5]}.',
      )
      ..writeln('Measured tenant A: 10,000 products / 5,000 customers / 50,000 orders.')
      ..writeln()
      ..writeln('| Path | Measure | ms | Seq scans on large tables |')
      ..writeln('|---|---|---:|---|');
  });

  tearDownAll(() async {
    if (!enabled) return;
    final out = File('build/perf-results.md');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(report.toString());
    stdout.writeln(report);
    await db.dispose();
  });

  void plan(String name, String sql, {Map<String, Object?> Function()? params, double budgetMs = 50}) {
    test(name, () async {
      final (ms, seq) = await explain(sql, params?.call() ?? const {});
      report.writeln(
        '| $name | EXPLAIN ANALYZE | ${ms.toStringAsFixed(2)} | ${seq.isEmpty ? 'none' : seq.join(', ')} |',
      );
      expect(seq, isEmpty, reason: 'sequential scan on large table');
      expect(ms, lessThan(budgetMs * budgetFactor));
    }, skip: enabled ? false : 'set VEPARI_SCALE=1 (tool/db_test.sh --scale)');
  }

  void rpc(String name, Future<void> Function() call, {double budgetMs = 100}) {
    test(name, () async {
      final ms = await medianMs(call);
      report.writeln('| $name | median of 7 RPC calls (client wall time) | ${ms.toStringAsFixed(2)} | n/a |');
      expect(ms, lessThan(budgetMs * budgetFactor));
    }, skip: enabled ? false : 'set VEPARI_SCALE=1 (tool/db_test.sh --scale)');
  }

  group('scale', () {
    plan('Catalogue first page', 'select * from public.catalogue_page(null, null, 30)');
    plan(
      'Catalogue deep keyset page',
      "select * from public.catalogue_page(now() - interval '5000 minutes', 'ffffffff-ffff-4fff-bfff-ffffffffffff', 30)",
    );
    plan(
      'Navo Maal (last 7 days)',
      "select * from public.catalogue_page(null, null, 30, null, now() - interval '7 days')",
    );
    plan('Product detail', 'select * from public.products where id = @p::uuid', params: () => {'p': a.kundan});
    plan(
      'Customers sorted by Baki',
      'select c.id, c.name, b.balance_paise from public.customer_balances b '
          'join public.customers c on c.tenant_id = b.tenant_id and c.id = b.customer_id '
          'where b.tenant_id = @t::uuid and b.balance_paise <> 0 order by b.balance_paise desc limit 30',
      params: () => {'t': a.tenantId},
    );
    plan(
      'Customer Hisaab (latest 50)',
      'select id, kind, amount_paise, balance_after_paise, created_at from public.ledger_entries where tenant_id = @t::uuid and customer_id = @c::uuid '
          'order by created_at desc, id desc limit 50',
      params: () => {'t': a.tenantId, 'c': sampleCustomer},
    );
    plan(
      'Customer orders (latest 20)',
      'select id, order_no, status, total_qty, total_paise, created_at from public.orders where tenant_id = @t::uuid and customer_id = @c::uuid '
          'order by created_at desc, id desc limit 20',
      params: () => {'t': a.tenantId, 'c': sampleCustomer},
    );
    plan(
      'Pending orders',
      "select id, order_no, customer_id, status, total_paise, created_at from public.orders where tenant_id = @t::uuid and status in ('confirmed','processing','ready') "
          'order by created_at desc limit 30',
      params: () => {'t': a.tenantId},
    );
    plan('Regular Maal', 'select * from public.regular_maal(@c::uuid)', params: () => {'c': sampleCustomer});

    rpc('search_all: design number', () => owner.query("select * from public.search_all('D4242')"));
    rpc('search_all: design name', () => owner.query("select * from public.search_all('kundan')"));
    rpc('search_all: customer name', () => owner.query("select * from public.search_all('mahesh')"));
    rpc('search_all: phone digits', () => owner.query("select * from public.search_all('98000042')"));
    rpc('dashboard_summary', () => owner.query('select public.dashboard_summary()'), budgetMs: 150);
    rpc(
      'create_order (3 lines)',
      () => owner.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
        'c': sampleCustomer,
        'items': orderItems([(a.kundan, 20), (a.jhumka, 10), (a.haar, 5)]),
        'r': TestDb.newId(),
      }),
    );
    rpc(
      'record_payment',
      () => owner.query("select public.record_payment(@c::uuid, 10000, 'upi', @r::uuid)", {
        'c': sampleCustomer,
        'r': TestDb.newId(),
      }),
    );
  });
}
