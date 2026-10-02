// The push webhook: each new notification queues one pg_net request to
// push-dispatch, carrying the notification id and the shared secret only.
// The shim records requests in net.shim_requests instead of sending them.
import 'package:test/test.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

void main() {
  late TestDb db;
  late TenantFixture a;
  late Actor owner;
  late Actor staff;

  const url = 'https://example-ref.supabase.co/functions/v1/push-dispatch';
  const secret = 'test-webhook-secret-0123456789abcdef';

  Future<List<List<Object?>>> requests() async => [
    for (final r in await db.admin.execute('select url, headers, body from net.shim_requests order by id')) r,
  ];

  Future<void> addProduct(String designNo) => owner.query(
    "insert into public.products (design_no, name, rate_paise) values (@d, 'Webhook Haar', 5000)",
    {'d': designNo},
  );

  setUpAll(() async {
    db = await TestDb.create();
    a = (await seedWorld(db.admin)).first;
    owner = await db.actor(a.ownerId);
    staff = await db.actor(a.staffFullId);
  });

  tearDownAll(() => db.dispose());

  setUp(() => db.admin.execute('truncate net.shim_requests'));

  test('without Vault configuration nothing is sent', () async {
    await addProduct('W-0');
    expect(await requests(), isEmpty);
  });

  group('configured', () {
    setUpAll(() async {
      await db.admin.execute("select vault.create_secret('$url', 'vepari_push_url')");
      await db.admin.execute("select vault.create_secret('$secret', 'vepari_push_secret')");
    });

    test('one request per notification row, id and secret only', () async {
      await addProduct('W-1');
      final rows = await db.admin.execute(
        "select id::text from public.notifications where args->>'design_no' = 'W-1' order by id",
      );
      expect(rows, isNotEmpty);
      final sent = await requests();
      expect(sent, hasLength(rows.length));
      for (final r in sent) {
        expect(r[0], url);
        expect(r[1], {'Content-Type': 'application/json', 'x-webhook-secret': secret});
        final body = r[2]! as Map;
        expect(body.keys.toSet(), {'type', 'schema', 'table', 'record'});
        expect(body['type'], 'INSERT');
        expect(body['table'], 'notifications');
        expect((body['record'] as Map).keys.toList(), ['id'], reason: 'no names, amounts or args in the webhook');
      }
      expect({for (final r in sent) (r[2]! as Map)['record']['id']}, {for (final r in rows) r.first});
    });

    test('payments: the webhook never carries the amount', () async {
      await staff.json("select public.record_payment(@c::uuid, 777700, 'cash', @r::uuid)", {
        'c': a.rajesh,
        'r': TestDb.newId(),
      });
      final sent = await requests();
      expect(sent, isNotEmpty);
      for (final r in sent) {
        expect('${r[2]}', isNot(contains('777700')));
      }
    });

    test('push targets name what the notification is about', () async {
      final service = await db.serviceRole();
      await staff.query("select public.register_device_token(@t, 'android', 'gu')", {
        't': 'fcm-token-owner-phone-webhook-000001',
      });
      await addProduct('W-2');
      final n = await db.admin.execute(
        "select id::text from public.notifications where recipient_id = \$1 and args->>'design_no' = 'W-2'",
        parameters: [a.staffFullId],
      );
      final targets = await service.query(
        'select kind, target_kind, target_id::text from public.push_targets(@n::uuid)',
        {'n': n.single.first},
      );
      final product = await db.admin.execute("select id::text from public.products where design_no = 'W-2'");
      expect(targets.single, ['new_maal', 'product', product.single.first]);
    });
  });

  test('the webhook secret is readable only by the service role', () async {
    final service = await db.serviceRole();
    expect(await service.scalar('select public.push_webhook_secret()'), secret);
    final anon = await db.actor(null);
    await expectLater(() => owner.query('select public.push_webhook_secret()'), throwsDbError(insufficientPrivilege));
    await expectLater(() => anon.query('select public.push_webhook_secret()'), throwsDbError(insufficientPrivilege));
    await expectLater(() => owner.query('select * from vault.decrypted_secrets'), throwsDbError(insufficientPrivilege));
  });
}
