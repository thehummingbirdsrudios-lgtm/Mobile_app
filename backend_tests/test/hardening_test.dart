// Hardening: storage access (share bucket closed, originals restricted),
// platform settings (version gate, maintenance pauses business writes).
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late Actor owner;
  late Actor staffMin;
  late Actor staffFull;
  late String folder;

  setUpAll(() async {
    db = await TestDb.create();
    a = (await seedWorld(db.admin)).first;
    owner = await db.actor(a.ownerId);
    staffMin = await db.actor(a.staffMinId);
    staffFull = await db.actor(a.staffFullId);
    folder = '${a.tenantId}/products/${a.kundan}/${TestDb.newId()}';
    await db.admin.execute(
      Sql.named(
        "insert into storage.objects (bucket_id, name) values "
        "('product-media', @o), ('product-media', @t), ('share', @s)",
      ),
      parameters: {'o': '$folder/original.jpg', 't': '$folder/thumb.jpg', 's': '${a.tenantId}/share/old.pdf'},
    );
  });

  tearDownAll(() => db.dispose());

  Future<Set<String>> visible(Actor who) async =>
      (await who.query('select name from storage.objects')).map((r) => r.first! as String).toSet();

  group('storage', () {
    test('photo originals: owner and catalogue managers only; everyone sees derivatives', () async {
      expect(await visible(staffMin), allOf(contains('$folder/thumb.jpg'), isNot(contains('$folder/original.jpg'))));
      expect(await visible(staffFull), contains('$folder/original.jpg'));
      expect(await visible(owner), contains('$folder/original.jpg'));
    });

    test('the share bucket is closed to app users', () async {
      expect(await visible(owner), isNot(contains('${a.tenantId}/share/old.pdf')));
      await expectLater(
        () => owner.query("insert into storage.objects (bucket_id, name) values ('share', @n)", {
          'n': '${a.tenantId}/share/new.pdf',
        }),
        throwsDbError(insufficientPrivilege),
      );
      expect(await owner.count("delete from storage.objects where bucket_id = 'share' returning 1"), 0);
    });

    test('derivative uploads still work for catalogue managers only', () async {
      await staffFull.query("insert into storage.objects (bucket_id, name) values ('product-media', @n)", {
        'n': '$folder/catalogue.jpg',
      });
      await expectLater(
        () => staffMin.query("insert into storage.objects (bucket_id, name) values ('product-media', @n)", {
          'n': '$folder/share.jpg',
        }),
        throwsDbError(insufficientPrivilege),
      );
    });
  });

  group('platform settings', () {
    test('app_status is readable before sign-in; the table itself is not', () async {
      final anon = await db.actor(null);
      expect(await anon.scalar('select public.app_status()'), {'min_app_version': '0.0.0', 'maintenance': false});
      await expectLater(
        () => owner.query('select * from public.platform_settings'),
        throwsDbError(insufficientPrivilege),
      );
      await expectLater(
        () => owner.query("update public.platform_settings set min_app_version = '9.9.9'"),
        throwsDbError(insufficientPrivilege),
      );
    });

    test('maintenance pauses business writes but not reads, and not operators', () async {
      await db.admin.execute('update public.platform_settings set maintenance = true');
      try {
        await expectLater(
          () => owner.query('select public.create_order(@c::uuid, @items::jsonb, @r::uuid)', {
            'c': a.rajesh,
            'items': orderItems([(a.kundan, 1)]),
            'r': TestDb.newId(),
          }),
          throwsDbError('maintenance'),
        );
        await expectLater(
          () => owner.query("select public.record_payment(@c::uuid, 100, 'cash', @r::uuid)", {
            'c': a.rajesh,
            'r': TestDb.newId(),
          }),
          throwsDbError('maintenance'),
        );
        await expectLater(
          () => owner.query("insert into public.customers (name) values ('During maintenance')"),
          throwsDbError('maintenance'),
        );
        await expectLater(
          () => owner.query("update public.products set name = 'X' where id = @p::uuid", {'p': a.kundan}),
          throwsDbError('maintenance'),
        );
        // Reads keep working.
        expect(await owner.count('select 1 from public.customers'), greaterThan(0));
        expect(await owner.scalar('select public.dashboard_summary()'), isNotNull);
        expect(await owner.scalar('select public.app_status()'), containsPair('maintenance', true));
        // Operators can still act (e.g. provisioning through the service role).
        final service = await db.serviceRole();
        final userId = TestDb.newId();
        await db.admin.execute('insert into auth.users (id) values (\$1)', parameters: [userId]);
        await service.query("select public.staff_admin_create(@a::uuid, @u::uuid, 'maint_staff', 'M', '{}')", {
          'a': a.ownerId,
          'u': userId,
        });
      } finally {
        await db.admin.execute('update public.platform_settings set maintenance = false');
      }
      // Back to normal.
      await owner.query("insert into public.customers (name) values ('After maintenance')");
    });
  });
}
