import 'package:postgres/postgres.dart';

import 'harness.dart';

/// Everything one tenant owns in the fixture world. Tenants A, B and C are
/// intentionally near-identical (same design numbers, product names and
/// customer names) so a leak cannot hide behind "different looking" data.
class TenantFixture {
  TenantFixture(this.label);

  final String label;
  late final String tenantId;
  late final String ownerId;

  /// Staff with every grantable permission.
  late final String staffFullId;

  /// Staff with no extra permissions (browse catalogue / customers / orders).
  late final String staffMinId;

  final Map<String, String> productIds = {};
  final Map<String, String> customerIds = {};
  late final String mediaId;

  String get kundan => productIds['1024']!;
  String get jhumka => productIds['1025']!;
  String get haar => productIds['1032']!;
  String get archived => productIds['0999']!;
  String get unavailable => productIds['1050']!;
  String get rajesh => customerIds['Rajeshbhai']!;
  String get suresh => customerIds['Sureshbhai']!;
}

const secretSupplier = 'XYZ Supplier SECRET';
const secretNote = 'INTERNAL-NOTE-SECRET';
const secretCostPaise = 41234;

const allGrantable = [
  'catalogue.manage',
  'rates.manage',
  'customers.manage',
  'orders.create',
  'orders.manage',
  'payments.record',
  'hisaab.view',
  'hisaab.adjust',
  'bills.issue',
  'reports.view',
];

Future<TenantFixture> seedTenant(Connection admin, String label) async {
  final t = TenantFixture(label);
  final lower = label.toLowerCase();

  Future<String> authUser(String username) async {
    final id = TestDb.newId();
    await admin.execute(
      Sql.named('insert into auth.users (id, email) values (@id::uuid, @email)'),
      parameters: {'id': id, 'email': '$username@login.vepari.invalid'},
    );
    return id;
  }

  t.ownerId = await authUser('owner_$lower');
  final created = await admin.execute(
    Sql.named('select public.admin_create_tenant(@slug, @name, @owner::uuid, @username, @display)'),
    parameters: {
      'slug': 'tenant-$lower',
      'name': 'Shree Jewels',
      'owner': t.ownerId,
      'username': 'owner_$lower',
      'display': 'Rajeshbhai Owner',
    },
  );
  t.tenantId = created.first.first! as String;

  t.staffFullId = await authUser('staff_full_$lower');
  await admin.execute(
    Sql.named(
      "select public.admin_add_member(@t::uuid, @u::uuid, @n, 'Full Staff', 'staff', @p::public.app_permission[])",
    ),
    parameters: {'t': t.tenantId, 'u': t.staffFullId, 'n': 'staff_full_$lower', 'p': '{${allGrantable.join(',')}}'},
  );
  t.staffMinId = await authUser('staff_min_$lower');
  await admin.execute(
    Sql.named("select public.admin_add_member(@t::uuid, @u::uuid, @n, 'Min Staff', 'staff')"),
    parameters: {'t': t.tenantId, 'u': t.staffMinId, 'n': 'staff_min_$lower'},
  );

  await admin.execute(
    Sql.named("update public.business_profiles set whatsapp_phone = '+919800000000' where tenant_id = @t::uuid"),
    parameters: {'t': t.tenantId},
  );

  Future<String> product(
    String designNo,
    String name,
    int ratePaise, {
    int? weightMg,
    bool available = true,
    bool archived = false,
  }) async {
    final r = await admin.execute(
      Sql.named('''
        insert into public.products (tenant_id, design_no, name, rate_paise, weight_mg, is_available,
                                     status, archived_at)
        values (@t::uuid, @d, @n, @r, @w, @a,
                case when @arch then 'archived' else 'active' end::public.product_status,
                case when @arch then now() end)
        returning id'''),
      parameters: {
        't': t.tenantId,
        'd': designNo,
        'n': name,
        'r': ratePaise,
        'w': weightMg,
        'a': available,
        'arch': archived,
      },
    );
    final id = r.first.first! as String;
    t.productIds[designNo] = id;
    return id;
  }

  await product('1024', 'Kundan Set કુંદન', 62000, weightMg: 42000);
  await product('1025', 'Jhumka झुमका', 32000, weightMg: 18000);
  await product('1032', 'Rani Haar', 150000);
  await product('0999', 'Old Design', 10000, archived: true);
  await product('1050', 'Out of stock design', 20000, available: false);

  await admin.execute(
    Sql.named('''
      insert into public.product_private (tenant_id, product_id, cost_paise, supplier_name, internal_note)
      values (@t::uuid, @p::uuid, @c, @s, @n)'''),
    parameters: {'t': t.tenantId, 'p': t.kundan, 'c': secretCostPaise, 's': secretSupplier, 'n': secretNote},
  );

  final media = await admin.execute(
    Sql.named('''
      insert into public.product_media (tenant_id, product_id, kind, status, mime_type, original_path,
        catalogue_path, share_path, thumb_path, width, height, bytes, sha256)
      values (@t::uuid, @p::uuid, 'image', 'ready', 'image/jpeg',
        @t || '/products/1024/original.jpg', @t || '/products/1024/catalogue.jpg',
        @t || '/products/1024/share.jpg', @t || '/products/1024/thumb.jpg',
        3000, 3000, 2500000, repeat('a', 64))
      returning id'''),
    parameters: {'t': t.tenantId, 'p': t.kundan},
  );
  t.mediaId = media.first.first! as String;

  Future<void> customer(String name, String phone) async {
    final r = await admin.execute(
      Sql.named('''
        insert into public.customers (tenant_id, name, phone, city, notes)
        values (@t::uuid, @n, @ph, 'Rajkot', 'private customer note')
        returning id'''),
      parameters: {'t': t.tenantId, 'n': name, 'ph': phone},
    );
    t.customerIds[name] = r.first.first! as String;
  }

  await customer('Rajeshbhai', '+919825000001');
  await customer('Sureshbhai', '+919825000002');

  // Rajeshbhai gets a special rate on 1024.
  await admin.execute(
    Sql.named('''
      insert into public.customer_product_rates (tenant_id, customer_id, product_id, rate_paise)
      values (@t::uuid, @c::uuid, @p::uuid, 60000)'''),
    parameters: {'t': t.tenantId, 'c': t.rajesh, 'p': t.kundan},
  );

  return t;
}

/// Seeds tenants A, B, C.
Future<List<TenantFixture>> seedWorld(Connection admin) async => [
  await seedTenant(admin, 'A'),
  await seedTenant(admin, 'B'),
  await seedTenant(admin, 'C'),
];

String orderItems(List<(String productId, int qty)> items, {Map<String, int>? expectedRates}) {
  final parts = items.map((i) {
    final expected = expectedRates?[i.$1];
    return '{"product_id":"${i.$1}","qty":${i.$2}'
        '${expected == null ? '' : ',"expected_rate_paise":$expected'}}';
  });
  return '[${parts.join(',')}]';
}
