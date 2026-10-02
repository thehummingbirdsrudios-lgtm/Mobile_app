// Owner/staff authorization (enforced in the database, not hidden buttons),
// privacy of owner-only data, safe-share payloads and universal search.
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
  late Actor staffCatalogue;
  late String billId;

  setUpAll(() async {
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    b = world[1];
    owner = await db.actor(a.ownerId);
    staffFull = await db.actor(a.staffFullId);
    staffMin = await db.actor(a.staffMinId);

    final catalogueOnly = TestDb.newId();
    await db.admin.execute('insert into auth.users (id) values (\$1)', parameters: [catalogueOnly]);
    await db.admin.execute(
      Sql.named(
        "select public.admin_add_member(@t::uuid, @u::uuid, 'staff_cat_a', 'Catalogue Staff', 'staff', '{catalogue.manage}')",
      ),
      parameters: {'t': a.tenantId, 'u': catalogueOnly},
    );
    staffCatalogue = await db.actor(catalogueOnly);

    final order = await owner.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
      'c': a.rajesh,
      'items': orderItems([(a.kundan, 20), (a.jhumka, 10)]),
      'r': TestDb.newId(),
    });
    billId = (await owner.json('select public.issue_bill(@o::uuid)', {'o': order['order_id']}))['bill_id'] as String;
  });

  tearDownAll(() => db.dispose());

  group('owner-only data', () {
    test('cost/supplier/notes are invisible to every staff member', () async {
      expect(await owner.count('select 1 from public.product_private'), 1);
      expect(await staffFull.count('select 1 from public.product_private'), 0);
      expect(await staffMin.count('select 1 from public.product_private'), 0);
    });

    test('audit log is owner-only and records sensitive changes without secrets', () async {
      await owner.query('update public.product_private set cost_paise = 45000 where product_id = @p::uuid', {
        'p': a.kundan,
      });
      expect(await staffFull.count('select 1 from public.audit_logs'), 0);
      final rows = await owner.query(
        "select data::text from public.audit_logs where entity = 'product_private' and action = 'update'",
      );
      expect(rows, isNotEmpty);
      expect(rows.first.first, isNot(contains('45000')));
      expect(rows.first.first, contains('changed'));
    });

    test('rate changes are audited with before/after', () async {
      await owner.query('update public.products set rate_paise = 63000 where id = @p::uuid', {'p': a.kundan});
      final rows = await owner.query(
        "select data from public.audit_logs where entity = 'products' and action = 'update' and entity_id = @p::uuid",
        {'p': a.kundan},
      );
      final data = Map<String, dynamic>.from(rows.last.first! as Map);
      expect(data['rate_paise'], {'from': 62000, 'to': 63000});
      await owner.query('update public.products set rate_paise = 62000 where id = @p::uuid', {'p': a.kundan});
    });

    test('business settings: owner only', () async {
      final staffUpdate = await staffFull.query("update public.business_profiles set business_name = 'X' returning 1");
      expect(staffUpdate, isEmpty);
      final ownerUpdate = await owner.query(
        "update public.business_profiles set business_name = 'Shree Jewels Rajkot' returning 1",
      );
      expect(ownerUpdate, hasLength(1));
      await expectLater(
        () => owner.query('update public.business_profiles set tenant_id = gen_random_uuid()'),
        throwsDbError(insufficientPrivilege),
      );
    });
  });

  group('current_session', () {
    test('returns identity, tenant, role and permissions of the caller only', () async {
      final session = await staffCatalogue.json('select public.current_session()');
      expect(session['tenant_id'], a.tenantId);
      expect(session['role'], 'staff');
      expect(session['username'], 'staff_cat_a');
      expect(session['permissions'], ['catalogue.manage']);
      expect(session['business_name'], isNotEmpty);
    });

    test('is null for deactivated staff and unknown users', () async {
      await owner.query('select public.set_member_active(@u::uuid, false)', {'u': a.staffMinId});
      expect(await staffMin.scalar('select public.current_session()'), isNull);
      await owner.query('select public.set_member_active(@u::uuid, true)', {'u': a.staffMinId});
      final stranger = await db.actor(TestDb.newId());
      expect(await stranger.scalar('select public.current_session()'), isNull);
    });
  });

  group('staff permissions are enforced server-side', () {
    test('Hisaab needs hisaab.view', () async {
      expect(await staffMin.count('select 1 from public.customer_balances'), 0);
      expect(await staffMin.count('select 1 from public.ledger_entries'), 0);
      expect(await staffMin.count('select 1 from public.payments'), 0);
      expect(await staffMin.count('select 1 from public.bills'), 0);
      expect(await staffFull.count('select 1 from public.customer_balances'), greaterThan(0));
      expect(await staffFull.count('select 1 from public.ledger_entries'), greaterThan(0));
    });

    test('everyone can browse maal, customers and orders', () async {
      expect(await staffMin.count('select 1 from public.products'), greaterThan(0));
      expect(await staffMin.count('select 1 from public.customers'), greaterThan(0));
      expect(await staffMin.count('select 1 from public.orders'), greaterThan(0));
    });

    test('catalogue writes need catalogue.manage', () async {
      await expectLater(
        () => staffMin.query("insert into public.products (design_no, name, rate_paise) values ('2001', 'X', 100)"),
        throwsDbError(insufficientPrivilege),
      );
      final created = await staffCatalogue.scalar(
        "insert into public.products (design_no, name, rate_paise) values ('2001', 'Navi Bangdi', 45000) returning id",
      );
      expect(created, isNotNull);
    });

    test('changing a rate additionally needs rates.manage', () async {
      final renamed = await staffCatalogue.query(
        "update public.products set name = 'Kundan Set New' where id = @p::uuid returning id",
        {'p': a.kundan},
      );
      expect(renamed, hasLength(1));
      await staffCatalogue.query("update public.products set name = 'Kundan Set કુંદન' where id = @p::uuid", {
        'p': a.kundan,
      });
      await expectLater(
        () => staffCatalogue.query('update public.products set rate_paise = 1 where id = @p::uuid', {'p': a.kundan}),
        throwsDbError('permission_denied'),
      );
      await expectLater(
        () => staffCatalogue.query(
          'insert into public.customer_product_rates (customer_id, product_id, rate_paise) values (@c::uuid, @p::uuid, 1)',
          {'c': a.suresh, 'p': a.kundan},
        ),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('customer writes need customers.manage', () async {
      await expectLater(
        () => staffMin.query("insert into public.customers (name) values ('Nope')"),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('no permission escalation', () async {
      await expectLater(
        () => staffFull.query("select public.set_member_permissions(@u::uuid, '{hisaab.view}')", {'u': a.staffMinId}),
        throwsDbError('permission_denied'),
      );
      await expectLater(
        () => staffMin.query(
          "insert into public.member_permissions (tenant_id, user_id, permission) values (@t::uuid, @u::uuid, 'hisaab.view')",
          {'t': a.tenantId, 'u': a.staffMinId},
        ),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => staffMin.query("update public.tenant_members set role = 'owner' where user_id = @u::uuid", {
          'u': a.staffMinId,
        }),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => staffFull.query("select public.admin_add_member(@t::uuid, gen_random_uuid(), 'evil', 'Evil', 'owner')", {
          't': a.tenantId,
        }),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('owner grants and revokes permissions', () async {
      await owner.query("select public.set_member_permissions(@u::uuid, '{hisaab.view}')", {'u': a.staffMinId});
      expect(await staffMin.count('select 1 from public.customer_balances'), greaterThan(0));
      await owner.query("select public.set_member_permissions(@u::uuid, '{}')", {'u': a.staffMinId});
      expect(await staffMin.count('select 1 from public.customer_balances'), 0);
    });

    test('dashboard needs reports.view', () async {
      await expectLater(() => staffMin.query('select public.dashboard_summary()'), throwsDbError('permission_denied'));
      final summary = await owner.json('select public.dashboard_summary()');
      expect(summary['sales_today_paise'], 20 * 60000 + 10 * 32000);
      expect(summary['orders_today'], 1);
      expect(summary['pending_orders'], 1);
      expect(summary['total_baki_paise'], 20 * 60000 + 10 * 32000);
    });

    test('remarks: only the author or owner can archive', () async {
      final id = await staffFull.scalar(
        "insert into public.remarks (kind, text_body, customer_id) values ('text', 'red stone check karjo', @c::uuid) returning id",
        {'c': a.rajesh},
      );
      final byOther = await staffMin.query(
        'update public.remarks set archived_at = now() where id = @id::uuid returning 1',
        {'id': id},
      );
      expect(byOther, isEmpty);
      final byOwner = await owner.query(
        'update public.remarks set archived_at = now() where id = @id::uuid returning 1',
        {'id': id},
      );
      expect(byOwner, hasLength(1));
    });

    test('remarks need exactly one parent and valid content', () async {
      await expectLater(
        () => staffMin.query("insert into public.remarks (kind, text_body) values ('text', 'orphan')"),
        throwsDbError('23514'),
      );
      await expectLater(
        () => staffMin.query("insert into public.remarks (kind, customer_id) values ('voice', @c::uuid)", {
          'c': a.rajesh,
        }),
        throwsDbError('23514'),
      );
    });
  });

  group('review regressions', () {
    test('taking a payment with an order needs payments.record too', () async {
      final orderOnly = TestDb.newId();
      await db.admin.execute('insert into auth.users (id) values (\$1)', parameters: [orderOnly]);
      await db.admin.execute(
        Sql.named(
          "select public.admin_add_member(@t::uuid, @u::uuid, 'staff_order_a', 'Order Staff', 'staff', '{orders.create}')",
        ),
        parameters: {'t': a.tenantId, 'u': orderOnly},
      );
      final staff = await db.actor(orderOnly);
      await expectLater(
        () => staff.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid, null, null, @pay::jsonb)', {
          'c': a.rajesh,
          'items': orderItems([(a.jhumka, 1)]),
          'r': TestDb.newId(),
          'pay': '{"amount_paise": 500000, "mode": "cash"}',
        }),
        throwsDbError('permission_denied'),
      );
      // Without a payment the same staff can still order.
      final ok = await staff.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
        'c': a.rajesh,
        'items': orderItems([(a.jhumka, 1)]),
        'r': TestDb.newId(),
      });
      expect(ok['order_no'], isNotNull);
    });

    test('idempotency keys are not readable by any member', () async {
      for (final table in ['orders', 'payments', 'ledger_entries']) {
        await expectLater(
          () => owner.query('select client_request_id from public.$table limit 1'),
          throwsDbError(insufficientPrivilege),
          reason: table,
        );
      }
      expect(await staffMin.count('select id, order_no from public.orders'), greaterThan(0));
    });

    test('replaying an order never reveals its payment to a caller without payment access', () async {
      final requestId = TestDb.newId();
      await owner.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid, null, null, @pay::jsonb)', {
        'c': a.suresh,
        'items': orderItems([(a.jhumka, 2)]),
        'r': requestId,
        'pay': '{"amount_paise": 20000, "mode": "cash"}',
      });
      final orderOnly = TestDb.newId();
      await db.admin.execute('insert into auth.users (id) values (\$1)', parameters: [orderOnly]);
      await db.admin.execute(
        Sql.named(
          "select public.admin_add_member(@t::uuid, @u::uuid, 'staff_replay_a', 'Replay Staff', 'staff', '{orders.create}')",
        ),
        parameters: {'t': a.tenantId, 'u': orderOnly},
      );
      final staff = await db.actor(orderOnly);
      final replay = await staff.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
        'c': '00000000-0000-0000-0000-000000000000',
        'items': '[]',
        'r': requestId,
      });
      expect(replay['replayed'], isTrue);
      expect(replay.containsKey('payment'), isFalse);
      final ownerReplay = await owner.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
        'c': a.suresh,
        'items': '[]',
        'r': requestId,
      });
      expect(ownerReplay['payment']['amount_paise'], 20000);
    });

    test('bill PDFs in storage need bills.issue or hisaab.view', () async {
      await db.admin.execute(
        "insert into storage.objects (bucket_id, name) values ('bills', \$1)",
        parameters: ['${a.tenantId}/bills/1/bill.pdf'],
      );
      expect(await staffMin.count("select 1 from storage.objects where bucket_id = 'bills'"), 0);
      expect(await staffFull.count("select 1 from storage.objects where bucket_id = 'bills'"), 1);
    });

    test('no object can be moved into the bills bucket without bills.issue', () async {
      // share: closed to app users (20261001001500); remarks: staff may upload.
      final shareName = '${a.tenantId}/share/forged.pdf';
      await db.admin.execute(
        Sql.named("insert into storage.objects (bucket_id, name) values ('share', @n)"),
        parameters: {'n': shareName},
      );
      final remarkName = '${a.tenantId}/remarks/forged.pdf';
      await staffMin.query("insert into storage.objects (bucket_id, name) values ('remarks', @n)", {'n': remarkName});
      for (final (bucket, name) in [('share', shareName), ('remarks', remarkName)]) {
        final moved = await staffMin.count(
          "update storage.objects set bucket_id = 'bills', name = @to where bucket_id = @b and name = @n returning 1",
          {'b': bucket, 'n': name, 'to': '${a.tenantId}/bills/9/$bucket.pdf'},
        );
        expect(moved, 0, reason: bucket);
      }
      final moved = await db.admin.execute(
        Sql.named("select count(*) from storage.objects where bucket_id = 'bills' and name like @p"),
        parameters: {'p': '${a.tenantId}/bills/9/%'},
      );
      expect(moved.single.first, 0);
    });
  });

  group('safe share', () {
    const allowedProductKeys = {
      'design_no',
      'name',
      'rate_paise',
      'weight_mg',
      'share_path',
      'business_name',
      'whatsapp_phone',
      'watermark_enabled',
    };

    void expectNoSecrets(String payload) {
      for (final secret in [
        secretSupplier,
        secretNote,
        '$secretCostPaise',
        'private customer note',
        'original.jpg',
        b.tenantId,
      ]) {
        expect(payload, isNot(contains(secret)), reason: 'leaked "$secret"');
      }
    }

    test('product share has an explicit allow-list of fields', () async {
      final payload = await staffMin.json('select public.share_product(@p::uuid)', {'p': a.kundan});
      expect(payload.keys.toSet(), allowedProductKeys);
      expect(payload['rate_paise'], 62000);
      expectNoSecrets(jsonEncode(payload));
    });

    test('customer share uses that customer rate only', () async {
      final forRajesh = await staffMin.json('select public.share_product(@p::uuid, @c::uuid)', {
        'p': a.kundan,
        'c': a.rajesh,
      });
      final forSuresh = await staffMin.json('select public.share_product(@p::uuid, @c::uuid)', {
        'p': a.kundan,
        'c': a.suresh,
      });
      expect(forRajesh['rate_paise'], 60000);
      expect(forSuresh['rate_paise'], 62000);
      expect(jsonEncode(forSuresh), isNot(contains('60000')));
    });

    test('archived designs cannot be shared', () async {
      await expectLater(
        () => staffMin.query('select public.share_product(@p::uuid)', {'p': a.archived}),
        throwsDbError('product_not_found'),
      );
    });

    test('bill payload contains no internal data', () async {
      final payload = await owner.json('select public.bill_payload(@b::uuid)', {'b': billId});
      expectNoSecrets(jsonEncode(payload));
      final items = (payload['items'] as List).cast<Map<String, dynamic>>();
      expect(items.first.keys.toSet(), {
        'design_no',
        'name',
        'qty',
        'rate_paise',
        'amount_paise',
        'weight_mg',
        'thumb_path',
        'image',
      });
      for (final item in items) {
        final image = item['image'] as Map<String, dynamic>?;
        if (image == null) continue;
        // Storage keys and dimensions only: never the original, never a URL.
        expect(image.keys.toSet(), {'source_path', 'thumb_path', 'width', 'height', 'sha256'});
        expect(image['source_path'] as String, isNot(contains('original')));
      }
      await expectLater(
        () => staffMin.query('select public.bill_payload(@b::uuid)', {'b': billId}),
        throwsDbError('bill_not_found'),
      );
    });
  });

  group('universal search', () {
    Future<List<List<Object?>>> search(String q) async => (await staffMin.query(
      'select kind, title from public.search_all(@q, 10)',
      {'q': q},
    )).map((r) => r.toList()).toList();

    test('design number: exact match ranks first', () async {
      final rows = await search('1024');
      expect(rows.first, ['product', '1024']);
    });

    test('design prefix', () async {
      final rows = await search('10');
      expect(rows.where((r) => r[0] == 'product').map((r) => r[1]), containsAll(['1024', '1025', '1032']));
      expect(rows.map((r) => r[1]), isNot(contains('0999')));
    });

    test('names in English, Gujarati and Hindi', () async {
      expect(await search('kundan'), anyElement(equals(['product', '1024'])));
      expect(await search('કુંદન'), anyElement(equals(['product', '1024'])));
      expect(await search('झुमका'), anyElement(equals(['product', '1025'])));
      expect(await search('rajesh'), anyElement(equals(['customer', 'Rajeshbhai'])));
    });

    test('customer by phone digits', () async {
      expect(await search('98250 00002'), anyElement(equals(['customer', 'Sureshbhai'])));
    });

    test('order by number', () async {
      final rows = await search('Order 1');
      expect(rows, anyElement(equals(['order', '1'])));
    });

    test('LIKE wildcards are literal, bounds are enforced', () async {
      expect(await search('%'), isEmpty);
      expect(await search('_'), isEmpty);
      expect(await search(''), isEmpty);
      expect(await search('   '), isEmpty);
      expect(await search('x' * 61), isEmpty);
      final limited = await staffMin.query("select * from public.search_all('1', 1000)");
      expect(limited.length, lessThanOrEqualTo(25 * 3));
    });
  });
}
