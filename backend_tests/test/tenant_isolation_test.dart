// RELEASE BLOCKER suite: Tenant A must never see, change, link to or infer
// Tenant B — via tables, RPCs, search, storage or manipulated ids.
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late TenantFixture b;
  late Actor ownerA;
  late Actor staffA;
  late String orderB;
  late String billB;
  late String paymentB;
  const deviceTokenB = 'fcm-token-of-a-tenant-b-staff-phone-0001';

  setUpAll(() async {
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    b = world[1];
    ownerA = await db.actor(a.ownerId);
    staffA = await db.actor(a.staffFullId);

    // Give tenant B real business history.
    final ownerB = await db.actor(b.ownerId);
    final order = await ownerB.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
      'c': b.rajesh,
      'items': orderItems([(b.kundan, 5)]),
      'r': TestDb.newId(),
    });
    orderB = order['order_id'] as String;
    final bill = await ownerB.json('select public.issue_bill(@o::uuid)', {'o': orderB});
    billB = bill['bill_id'] as String;
    final payment = await ownerB.json("select public.record_payment(@c::uuid, 10000, 'cash', @r::uuid)", {
      'c': b.rajesh,
      'r': TestDb.newId(),
    });
    paymentB = payment['payment_id'] as String;
    await ownerB.query(
      "insert into public.remarks (kind, text_body, customer_id) values ('text', 'B secret vaat', @c::uuid)",
      {'c': b.rajesh},
    );
    // B's staff get notifications for B's order and payment, on a B device.
    final staffB = await db.actor(b.staffFullId);
    await staffB.query("select public.register_device_token(@t, 'android', 'gu')", {'t': deviceTokenB});
  });

  tearDownAll(() => db.dispose());

  group('reads never cross tenants', () {
    const tenantTables = [
      'tenants',
      'tenant_members',
      'member_permissions',
      'app_users',
      'business_profiles',
      'categories',
      'products',
      'product_private',
      'product_media',
      'customers',
      'customer_balances',
      'customer_product_rates',
      'orders',
      'order_items',
      'payments',
      'ledger_entries',
      'bills',
      'remarks',
      'photo_enquiries',
      'share_assets',
      'notifications',
      'device_tokens',
      'audit_logs',
    ];

    for (final table in tenantTables) {
      test('$table: owner A sees no tenant-B rows', () async {
        final column = switch (table) {
          'tenants' => 'id',
          'app_users' => 'id',
          _ => 'tenant_id',
        };
        final leaked = table == 'app_users'
            ? await ownerA.count(
                'select 1 from public.app_users u join public.tenant_members m on m.user_id = u.id '
                'where m.tenant_id <> @t::uuid',
                {'t': a.tenantId},
              )
            : await ownerA.count('select 1 from public.$table where $column::uuid <> @t::uuid', {'t': a.tenantId});
        expect(leaked, 0);
      });
    }

    test('direct id lookup of B records returns nothing', () async {
      expect(await ownerA.count('select 1 from public.customers where id = @id::uuid', {'id': b.rajesh}), 0);
      expect(await ownerA.count('select 1 from public.products where id = @id::uuid', {'id': b.kundan}), 0);
      expect(await ownerA.count('select 1 from public.orders where id = @id::uuid', {'id': orderB}), 0);
      expect(await ownerA.count('select 1 from public.bills where id = @id::uuid', {'id': billB}), 0);
      expect(await ownerA.count('select 1 from public.payments where id = @id::uuid', {'id': paymentB}), 0);
      expect(
        await ownerA.count('select 1 from public.ledger_entries where customer_id = @id::uuid', {'id': b.rajesh}),
        0,
      );
    });

    test('anonymous callers see nothing at all', () async {
      final anon = await db.actor(null);
      await expectLater(() => anon.count('select 1 from public.customers'), throwsDbError(insufficientPrivilege));
      await expectLater(() => anon.count('select 1 from public.products'), throwsDbError(insufficientPrivilege));
      await expectLater(
        () => anon.query('select public.search_all(@q)', {'q': '1024'}),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('a user with no membership resolves no tenant', () async {
      final stranger = await db.actor(TestDb.newId());
      expect(await stranger.count('select 1 from public.products'), 0);
      await expectLater(
        () => stranger.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
          'c': a.rajesh,
          'items': orderItems([(a.kundan, 1)]),
          'r': TestDb.newId(),
        }),
        throwsDbError('not_authenticated'),
      );
    });
  });

  group('RPCs with manipulated ids', () {
    test('create_order for B customer fails', () async {
      await expectLater(
        () => ownerA.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
          'c': b.rajesh,
          'items': orderItems([(a.kundan, 1)]),
          'r': TestDb.newId(),
        }),
        throwsDbError('customer_not_found'),
      );
    });

    test('create_order with B product fails', () async {
      await expectLater(
        () => ownerA.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
          'c': a.rajesh,
          'items': orderItems([(b.kundan, 1)]),
          'r': TestDb.newId(),
        }),
        throwsDbError('product_not_found'),
      );
    });

    test('reorder_of a B order fails', () async {
      await expectLater(
        () => ownerA.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid, null, @ro::uuid)', {
          'c': a.rajesh,
          'items': orderItems([(a.kundan, 1)]),
          'r': TestDb.newId(),
          'ro': orderB,
        }),
        throwsDbError('order_not_found'),
      );
    });

    test('record_payment against B customer fails', () async {
      await expectLater(
        () => ownerA.query("select public.record_payment(@c::uuid, 100, 'cash', @r::uuid)", {
          'c': b.rajesh,
          'r': TestDb.newId(),
        }),
        throwsDbError('customer_not_found'),
      );
    });

    test('order status / cancel / bill on B order fail', () async {
      await expectLater(
        () => ownerA.query("select public.transition_order(@o::uuid, 'ready')", {'o': orderB}),
        throwsDbError('order_not_found'),
      );
      await expectLater(
        () => ownerA.query('select public.cancel_order(@o::uuid)', {'o': orderB}),
        throwsDbError('order_not_found'),
      );
      await expectLater(
        () => ownerA.query('select public.issue_bill(@o::uuid)', {'o': orderB}),
        throwsDbError('order_not_found'),
      );
    });

    test('bill_payload / share_product / reorder_preview / regular_maal reveal nothing of B', () async {
      await expectLater(
        () => ownerA.query('select public.bill_payload(@b::uuid)', {'b': billB}),
        throwsDbError('bill_not_found'),
      );
      await expectLater(
        () => ownerA.query('select public.share_product(@p::uuid)', {'p': b.kundan}),
        throwsDbError('product_not_found'),
      );
      await expectLater(
        () => ownerA.query('select public.share_product(@p::uuid, @c::uuid)', {'p': a.kundan, 'c': b.rajesh}),
        throwsDbError('customer_not_found'),
      );
      expect(await ownerA.count('select * from public.reorder_preview(@o::uuid)', {'o': orderB}), 0);
      expect(await ownerA.count('select * from public.regular_maal(@c::uuid)', {'c': b.rajesh}), 0);
    });

    test('adjustment / member management against B fail', () async {
      await expectLater(
        () => ownerA.query("select public.record_adjustment(@c::uuid, 'adjustment', 500, @r::uuid, 'x')", {
          'c': b.rajesh,
          'r': TestDb.newId(),
        }),
        throwsDbError('customer_not_found'),
      );
      await expectLater(
        () => ownerA.query("select public.set_member_permissions(@u::uuid, '{orders.create}')", {'u': b.staffMinId}),
        throwsDbError('member_not_found'),
      );
      await expectLater(
        () => ownerA.query('select public.set_member_active(@u::uuid, false)', {'u': b.staffFullId}),
        throwsDbError('member_not_found'),
      );
    });
  });

  group('writes cannot target or forge another tenant', () {
    test('client cannot supply tenant_id on insert', () async {
      await expectLater(
        () => staffA.query("insert into public.customers (tenant_id, name) values (@t::uuid, 'Forged')", {
          't': b.tenantId,
        }),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('inserted rows are stamped with the caller tenant', () async {
      final id = await staffA.scalar("insert into public.customers (name) values ('Navo Customer') returning id");
      final tenant = await db.admin.execute('select tenant_id from public.customers where id = \$1', parameters: [id]);
      expect(tenant.first.first, a.tenantId);
    });

    test('updates/archives of B rows affect zero rows', () async {
      final updated = await ownerA.query(
        "update public.products set name = 'hacked' where id = @p::uuid returning id",
        {'p': b.kundan},
      );
      expect(updated, isEmpty);
      final archived = await ownerA.query(
        'update public.customers set archived_at = now() where id = @c::uuid returning id',
        {'c': b.rajesh},
      );
      expect(archived, isEmpty);
    });

    test('cannot link own rows to B parents (composite FKs)', () async {
      await expectLater(
        () => ownerA.query("insert into public.remarks (kind, text_body, customer_id) values ('text', 'x', @c::uuid)", {
          'c': b.rajesh,
        }),
        throwsDbError('23503'),
      );
      await expectLater(
        () => ownerA.query(
          'insert into public.customer_product_rates (customer_id, product_id, rate_paise) values (@c::uuid, @p::uuid, 1)',
          {'c': a.rajesh, 'p': b.kundan},
        ),
        throwsDbError('23503'),
      );
    });

    test('cannot register media pointing at B storage paths', () async {
      await expectLater(
        () => ownerA.query(
          '''insert into public.product_media (product_id, kind, mime_type, original_path, bytes, sha256)
             values (@p::uuid, 'image', 'image/jpeg', @path, 10, repeat('b', 64))''',
          {'p': a.kundan, 'path': '${b.tenantId}/products/1024/original.jpg'},
        ),
        throwsDbError('23514'),
      );
    });
  });

  group('search does not reveal other tenants', () {
    test('identical design number and names only return own rows', () async {
      final rows = await ownerA.query('select kind, id from public.search_all(@q, 25)', {'q': '1024'});
      expect(rows, isNotEmpty);
      final ids = rows.map((r) => r[1]).toSet();
      expect(ids.contains(b.kundan), isFalse);
      expect(ids.contains(a.kundan), isTrue);

      final customers = await ownerA.query("select id from public.search_all('Rajesh', 25) where kind = 'customer'");
      expect(customers.map((r) => r[0]), [a.rajesh]);
    });

    test('order numbers that exist only in B are not found', () async {
      final rows = await ownerA.query("select id from public.search_all('1', 25) where kind = 'order'");
      expect(rows.map((r) => r[0]), isNot(contains(orderB)));
    });
  });

  group('storage objects are tenant-scoped', () {
    setUpAll(() async {
      await db.admin.execute(
        "insert into storage.objects (bucket_id, name) values ('product-media', \$1), ('product-media', \$2)",
        parameters: ['${a.tenantId}/products/1024/original.jpg', '${b.tenantId}/products/1024/original.jpg'],
      );
    });

    test('A lists only its own objects', () async {
      final rows = await ownerA.query('select name from storage.objects');
      expect(rows.map((r) => r[0] as String).every((n) => n.startsWith(a.tenantId)), isTrue);
      expect(rows, hasLength(1));
    });

    test('A cannot upload into B prefix', () async {
      await expectLater(
        () => ownerA.query("insert into storage.objects (bucket_id, name) values ('product-media', @n)", {
          'n': '${b.tenantId}/products/evil.jpg',
        }),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('A cannot delete B objects', () async {
      final deleted = await ownerA.query(
        "delete from storage.objects where bucket_id = 'product-media' and name like @n returning name",
        {'n': '${b.tenantId}%'},
      );
      expect(deleted, isEmpty);
    });
  });

  group('session revocation', () {
    test('deactivated staff loses access immediately', () async {
      final staffMin = await db.actor(a.staffMinId);
      expect(await staffMin.count('select 1 from public.products'), greaterThan(0));
      await ownerA.query('select public.set_member_active(@u::uuid, false)', {'u': a.staffMinId});
      expect(await staffMin.count('select 1 from public.products'), 0);
      await ownerA.query('select public.set_member_active(@u::uuid, true)', {'u': a.staffMinId});
    });

    test('suspended tenant loses access', () async {
      final c = await seedTenant(db.admin, 'S');
      final ownerC = await db.actor(c.ownerId);
      expect(await ownerC.count('select 1 from public.customers'), greaterThan(0));
      await db.admin.execute("update public.tenants set status = 'suspended' where id = \$1", parameters: [c.tenantId]);
      expect(await ownerC.count('select 1 from public.customers'), 0);
    });
  });

  group('notifications and devices', () {
    test('the inbox, unread count and mark-read only ever touch own rows', () async {
      final staffB = await db.actor(b.staffFullId);
      final bIds = (await staffB.query(
        'select id from public.notification_page(null, null, 100)',
      )).map((r) => r.first! as String).toList();
      expect(bIds, isNotEmpty, reason: 'B staff were notified of B activity');

      final aIds = (await ownerA.query(
        'select id from public.notification_page(null, null, 100)',
      )).map((r) => r.first! as String).toSet();
      expect(aIds.intersection(bIds.toSet()), isEmpty);
      final unreadA = await ownerA.scalar('select public.unread_notification_count()');
      expect(
        await ownerA.scalar('select public.mark_notifications_read(@ids::uuid[])', {'ids': '{${bIds.join(',')}}'}),
        0,
      );
      expect(await ownerA.scalar('select public.unread_notification_count()'), unreadA);
      expect(await staffB.scalar('select public.unread_notification_count()'), bIds.length);
    });

    test('a device token follows the login that registered it last', () async {
      final staffB = await db.actor(b.staffFullId);
      expect(await staffB.count('select 1 from public.device_tokens'), 1);
      // The phone is handed to someone in business A, who logs in.
      await ownerA.query("select public.register_device_token(@t, 'android', 'en')", {'t': deviceTokenB});
      expect(await staffB.count('select 1 from public.device_tokens'), 0);
      expect(await ownerA.count('select 1 from public.device_tokens where tenant_id = @t::uuid', {'t': a.tenantId}), 1);
      // B's notifications can no longer reach it.
      final service = await db.serviceRole();
      final bNotification = await staffB.scalar('select id from public.notification_page(null, null, 1)');
      expect(await service.count('select 1 from public.push_targets(@n::uuid)', {'n': bNotification}), 0);
    });

    test('unregistering only removes the caller\'s own token', () async {
      final staffB = await db.actor(b.staffFullId);
      await staffB.query("select public.register_device_token(@t, 'android', 'gu')", {'t': '$deviceTokenB-x'});
      await ownerA.query('select public.unregister_device_token(@t)', {'t': '$deviceTokenB-x'});
      expect(await staffB.count('select 1 from public.device_tokens'), 1);
    });

    test('app users cannot write tokens or notifications directly, nor read push targets', () async {
      await expectLater(
        () => ownerA.query(
          "insert into public.device_tokens (tenant_id, user_id, token, platform) "
          "values (@t::uuid, @u::uuid, 'forged-token-forged-token-1', 'android')",
          {'t': b.tenantId, 'u': b.ownerId},
        ),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => ownerA.query(
          "insert into public.notifications (tenant_id, recipient_id, kind, dedupe_key) "
          "values (@t::uuid, @u::uuid, 'new_maal', 'x')",
          {'t': b.tenantId, 'u': b.ownerId},
        ),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => ownerA.query('select * from public.push_targets(gen_random_uuid())'),
        throwsDbError(insufficientPrivilege),
      );
    });
  });
}
