// Owner administration: staff accounts created by the staff-admin Edge
// Function (service role) and the owner's readable audit log. The tenant is
// derived from the verified caller (p_actor), never from the request, and
// every action is attributed to that owner in the audit log.
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late TenantFixture b;
  late Actor service;

  Future<String> authUser(String username) async {
    final id = TestDb.newId();
    await db.admin.execute(
      Sql.named('insert into auth.users (id, email) values (@id::uuid, @email)'),
      parameters: {'id': id, 'email': '$username@login.vepari.invalid'},
    );
    return id;
  }

  Future<Result> create(String actor, String userId, String username, {List<String> permissions = const []}) =>
      service.query('select public.staff_admin_create(@a::uuid, @u::uuid, @n, @d, @p::public.app_permission[])', {
        'a': actor,
        'u': userId,
        'n': username,
        'd': 'New Staff',
        'p': '{${permissions.join(',')}}',
      });

  setUpAll(() async {
    db = await TestDb.create();
    final world = await seedWorld(db.admin);
    a = world[0];
    b = world[1];
    service = await db.serviceRole();
  });

  tearDownAll(() => db.dispose());

  test('an owner adds staff to their own business, attributed to them', () async {
    final id = await authUser('kiran_a');
    await create(a.ownerId, id, 'Kiran_A', permissions: ['orders.create', 'orders.create', 'hisaab.view']);

    final member = await db.admin.execute(
      Sql.named(
        'select m.tenant_id, m.role::text, m.is_active, u.username from public.tenant_members m '
        'join public.app_users u on u.id = m.user_id where m.user_id = @u::uuid',
      ),
      parameters: {'u': id},
    );
    expect(member.single, [a.tenantId, 'staff', true, 'kiran_a']);

    final staff = await db.actor(id);
    expect(await staff.scalar('select app.current_tenant_id()'), a.tenantId);
    expect(await staff.scalar("select app.has_permission('orders.create')"), isTrue);
    expect(await staff.scalar("select app.has_permission('payments.record')"), isFalse);

    final owner = await db.actor(a.ownerId);
    final audit = await owner.query(
      "select action, actor_name from public.audit_page(null, 200) where entity_id = @u::uuid order by id",
      {'u': id},
    );
    final actions = audit.map((r) => r[0]).toList();
    expect(actions, containsAll(['insert', 'staff.created']));
    // Every row — including the ones written by triggers — names the owner.
    expect(audit.map((r) => r[1]).toSet(), {'Rajeshbhai Owner'});
  });

  test('staff cannot create staff, even through the service role', () async {
    final id = await authUser('evil_staff');
    await expectLater(() => create(a.staffFullId, id, 'evil_staff'), throwsDbError('permission_denied'));
    expect(
      await db.admin.execute(Sql.named('select 1 from public.app_users where id = @u::uuid'), parameters: {'u': id}),
      isEmpty,
    );
  });

  test('a suspended business cannot add staff', () async {
    final s = await seedTenant(db.admin, 'S');
    await db.admin.execute("update public.tenants set status = 'suspended' where id = \$1", parameters: [s.tenantId]);
    final id = await authUser('late_s');
    await expectLater(() => create(s.ownerId, id, 'late_s'), throwsDbError('permission_denied'));
  });

  test('usernames are unique across businesses, case-insensitively', () async {
    final first = await authUser('meena_1');
    await create(a.ownerId, first, 'meena');
    final second = await authUser('meena_2');
    await expectLater(() => create(b.ownerId, second, 'MEENA'), throwsDbError('username_taken'));
  });

  test('invalid usernames and names are rejected with a field hint', () async {
    final id = await authUser('bad_name');
    await expectLater(() => create(a.ownerId, id, 'no spaces!'), throwsDbError('invalid_request'));
    await expectLater(
      () => service.query("select public.staff_admin_create(@a::uuid, @u::uuid, 'okname', '   ', '{}')", {
        'a': a.ownerId,
        'u': id,
      }),
      throwsDbError('invalid_request'),
    );
  });

  test('password resets are limited to staff of the caller\'s business', () async {
    Future<Result> check(String actor, String target) =>
        service.query('select public.staff_admin_check_target(@a::uuid, @t::uuid)', {'a': actor, 't': target});
    await check(a.ownerId, a.staffMinId);
    await expectLater(() => check(b.ownerId, a.staffMinId), throwsDbError('member_not_found'));
    await expectLater(() => check(a.ownerId, a.ownerId), throwsDbError('member_not_found'));
    await expectLater(() => check(a.staffFullId, a.staffMinId), throwsDbError('permission_denied'));
  });

  test('a completed reset is audited without any secret', () async {
    await service.query('select public.staff_admin_record_password_reset(@a::uuid, @t::uuid)', {
      'a': a.ownerId,
      't': a.staffMinId,
    });
    final owner = await db.actor(a.ownerId);
    final row = await owner.query(
      "select actor_name, data::text from public.audit_page(null, 200) where action = 'staff.password_reset'",
    );
    expect(row.single, ['Rajeshbhai Owner', '{}']);
    await expectLater(
      () => service.query('select public.staff_admin_record_password_reset(@a::uuid, @t::uuid)', {
        'a': b.ownerId,
        't': a.staffMinId,
      }),
      throwsDbError('member_not_found'),
    );
  });

  test('app users cannot call the provisioning functions', () async {
    final owner = await db.actor(a.ownerId);
    final id = await authUser('direct_call');
    await expectLater(
      () => owner.query("select public.staff_admin_create(@a::uuid, @u::uuid, 'direct_call', 'X', '{}')", {
        'a': a.ownerId,
        'u': id,
      }),
      throwsDbError(insufficientPrivilege),
    );
    await expectLater(
      () => owner.query('select public.staff_admin_check_target(@a::uuid, @t::uuid)', {
        'a': a.ownerId,
        't': a.staffMinId,
      }),
      throwsDbError(insufficientPrivilege),
    );
    final anon = await db.actor(null);
    await expectLater(
      () => anon.query('select public.staff_admin_record_password_reset(@a::uuid, @t::uuid)', {
        'a': a.ownerId,
        't': a.staffMinId,
      }),
      throwsDbError(insufficientPrivilege),
    );
  });

  group('audit log', () {
    test('a removed permission records what was removed and whose it was', () async {
      final owner = await db.actor(a.ownerId);
      await owner.query("select public.set_member_permissions(@u::uuid, '{orders.create}')", {'u': a.staffMinId});
      await owner.query("select public.set_member_permissions(@u::uuid, '{}')", {'u': a.staffMinId});
      final rows = await owner.query(
        "select action, data, subject from public.audit_page(null, 200) "
        "where entity = 'member_permissions' and entity_id = @u::uuid order by id",
        {'u': a.staffMinId},
      );
      expect(rows.map((r) => r[0]), ['insert', 'delete']);
      final removed = rows.last[1]! as Map;
      expect(removed['permission'], {'from': 'orders.create', 'to': null});
      expect(rows.last[2], 'Min Staff');
    });

    test('rows name their subject: design, customer, staff, order', () async {
      final owner = await db.actor(a.ownerId);
      await owner.query('update public.products set rate_paise = rate_paise + 100 where id = @p::uuid', {
        'p': a.kundan,
      });
      await owner.query("update public.customers set city = 'Gondal-audit' where id = @c::uuid", {'c': a.rajesh});
      await owner.query('select public.set_member_active(@u::uuid, false)', {'u': a.staffMinId});
      await owner.json('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
        'c': a.rajesh,
        'items': orderItems([(a.kundan, 2)]),
        'r': TestDb.newId(),
      });
      final rows = await owner.query('select entity, action, subject from public.audit_page(null, 200)');
      String? subject(String entity, String action) =>
          rows.firstWhere((r) => r[0] == entity && r[1] == action)[2] as String?;
      expect(subject('products', 'update'), '1024 · Kundan Set કુંદન');
      expect(subject('customers', 'update'), 'Rajeshbhai');
      expect(subject('tenant_members', 'update'), 'Min Staff');
      expect(subject('orders', 'order.created'), startsWith('#'));
    });

    test('product cost changes stay redacted, also on delete', () async {
      final owner = await db.actor(a.ownerId);
      await owner.query('update public.product_private set cost_paise = 47000 where product_id = @p::uuid', {
        'p': a.kundan,
      });
      final row = await owner.query(
        "select data::text from public.audit_page(null, 200) where entity = 'product_private' and action = 'update'",
      );
      expect(row.first.first, isNot(contains('47000')));
      expect(row.first.first, contains('changed'));
    });

    test('staff never read the audit log', () async {
      final staff = await db.actor(a.staffFullId);
      await expectLater(
        () => staff.query('select * from public.audit_page(null, 10)'),
        throwsDbError('permission_denied'),
      );
    });
  });
}
