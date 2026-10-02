// Notification fan-out: who is told about what. Rows are written in the same
// transaction as the event, never to the actor, only to active members who
// may see the subject, and only with fields those members may already see.
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late Actor owner;
  late Actor staffFull;
  late Actor staffMin;

  Future<List<Map<String, dynamic>>> inbox(Actor who) async => [
    for (final r in await who.query(
      'select kind, target_kind, args, read_at from public.notification_page(null, null, 100)',
    ))
      {'kind': r[0], 'target_kind': r[1], 'args': r[2], 'read_at': r[3]},
  ];

  setUpAll(() async {
    db = await TestDb.create();
    a = (await seedWorld(db.admin)).first;
    owner = await db.actor(a.ownerId);
    staffFull = await db.actor(a.staffFullId);
    staffMin = await db.actor(a.staffMinId);
    // Start from a clean inbox (fixtures created products as the admin).
    await db.admin.execute('delete from public.notifications');
  });

  tearDownAll(() => db.dispose());

  test('new Maal reaches every active member except who added it', () async {
    await owner.query("insert into public.products (design_no, name, rate_paise) values ('N-1', 'Navo Haar', 90000)");
    expect((await inbox(owner)).where((n) => n['kind'] == 'new_maal'), isEmpty);
    for (final staff in [staffFull, staffMin]) {
      final n = (await inbox(staff)).singleWhere((n) => n['kind'] == 'new_maal');
      expect(n['args'], {'design_no': 'N-1', 'name': 'Navo Haar'});
      expect(n['target_kind'], 'product');
    }
  });

  test('a new order tells the owner and order managers, not other staff', () async {
    await staffFull.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
      'c': a.rajesh,
      'items': orderItems([(a.kundan, 2)]),
      'r': TestDb.newId(),
    });
    final ownerOrder = (await inbox(owner)).singleWhere((n) => n['kind'] == 'order_update');
    expect((ownerOrder['args'] as Map)['event'], 'created');
    expect((ownerOrder['args'] as Map)['customer_name'], 'Rajeshbhai');
    expect((await inbox(staffFull)).where((n) => n['kind'] == 'order_update'), isEmpty, reason: 'the actor');
    expect((await inbox(staffMin)).where((n) => n['kind'] == 'order_update'), isEmpty, reason: 'no orders.manage');
  });

  test('a status change tells the person who took the order', () async {
    final order = await staffFull.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
      'c': a.suresh,
      'items': orderItems([(a.jhumka, 1)]),
      'r': TestDb.newId(),
    });
    await owner.query("select public.transition_order(@o::uuid, 'processing')", {'o': order['order_id']});
    final updates = (await inbox(staffFull)).where((n) => n['kind'] == 'order_update').toList();
    expect(updates.single['args'], containsPair('status', 'processing'));
  });

  test('payments reach only those who may see Hisaab, with the amount', () async {
    await staffFull.json("select public.record_payment(@c::uuid, 250000, 'upi', @r::uuid)", {
      'c': a.rajesh,
      'r': TestDb.newId(),
    });
    final n = (await inbox(owner)).singleWhere((n) => n['kind'] == 'payment_received');
    expect((n['args'] as Map)['amount_paise'], 250000);
    expect((await inbox(staffMin)).where((n) => n['kind'] == 'payment_received'), isEmpty);
  });

  test('nothing ever carries cost, supplier or internal notes', () async {
    final all = await db.admin.execute('select args::text from public.notifications');
    for (final r in all) {
      expect(r.first, isNot(contains(secretSupplier)));
      expect(r.first, isNot(contains(secretNote)));
      expect(r.first, isNot(contains('$secretCostPaise')));
    }
  });

  test('stopped staff are not notified', () async {
    await owner.query('select public.set_member_active(@u::uuid, false)', {'u': a.staffMinId});
    await owner.query("insert into public.products (design_no, name, rate_paise) values ('N-2', 'Bangdi', 9000)");
    final rows = await db.admin.execute(
      "select count(*) from public.notifications where recipient_id = \$1 and args->>'design_no' = 'N-2'",
      parameters: [a.staffMinId],
    );
    expect(rows.single.first, 0);
    await owner.query('select public.set_member_active(@u::uuid, true)', {'u': a.staffMinId});
  });

  test('mark read: one, then all; the count follows', () async {
    final before = (await staffFull.scalar('select public.unread_notification_count()'))! as int;
    expect(before, greaterThan(1));
    final first = await staffFull.scalar('select id from public.notification_page(null, null, 1)');
    expect(await staffFull.scalar('select public.mark_notifications_read(array[@n::uuid])', {'n': first}), 1);
    expect(await staffFull.scalar('select public.unread_notification_count()'), before - 1);
    expect(await staffFull.scalar('select public.mark_notifications_read()'), before - 1);
    expect(await staffFull.scalar('select public.unread_notification_count()'), 0);
  });

  test('push targets: active recipient devices only, and only while unread', () async {
    final service = await db.serviceRole();
    await staffMin.query("select public.register_device_token(@t, 'android', 'hi')", {
      't': 'fcm-token-staff-min-phone-000000001',
    });
    await owner.query("insert into public.products (design_no, name, rate_paise) values ('N-3', 'Payal', 7000)");
    final id = await db.admin.execute(
      "select id from public.notifications where recipient_id = \$1 and args->>'design_no' = 'N-3'",
      parameters: [a.staffMinId],
    );
    final notification = id.single.first! as String;
    final targets = await service.query('select token, locale, kind from public.push_targets(@n::uuid)', {
      'n': notification,
    });
    expect(targets.single, ['fcm-token-staff-min-phone-000000001', 'hi', 'new_maal']);

    await owner.query('select public.set_member_active(@u::uuid, false)', {'u': a.staffMinId});
    expect(await service.count('select 1 from public.push_targets(@n::uuid)', {'n': notification}), 0);
    await owner.query('select public.set_member_active(@u::uuid, true)', {'u': a.staffMinId});

    await service.query("select public.forget_device_tokens(array['fcm-token-staff-min-phone-000000001'])");
    expect(await service.count('select 1 from public.push_targets(@n::uuid)', {'n': notification}), 0);
  });

  test('token registration validates input and keeps at most 10 devices', () async {
    await expectLater(
      () => staffFull.query("select public.register_device_token('short', 'android', 'gu')"),
      throwsDbError('invalid_request'),
    );
    await expectLater(
      () => staffFull.query("select public.register_device_token(@t, 'symbian', 'gu')", {'t': 'x' * 30}),
      throwsDbError('invalid_request'),
    );
    for (var i = 0; i < 12; i++) {
      await staffFull.query("select public.register_device_token(@t, 'android', 'gu')", {
        't': 'fcm-token-many-devices-${i.toString().padLeft(4, '0')}',
      });
    }
    expect(await staffFull.count('select 1 from public.device_tokens'), 10);
  });
}
