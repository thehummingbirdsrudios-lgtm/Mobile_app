import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/state/paged.dart';
import '../../domain/customers.dart';

/// Remote data source for customers: read RPCs (RLS applies) and
/// RLS-protected table writes with column-level grants.
class CustomersApi {
  const CustomersApi(this._client, this._api);

  final SupabaseClient _client;
  final ApiClient _api;

  Future<PageResult<CustomerSummary, CustomerCursor>> page(
    CustomerQuery query, {
    CustomerCursor? after,
    required int limit,
  }) async {
    final rows = await _api.rpc(
      'customer_list',
      params: {
        'p_search': query.search.trim().isEmpty ? null : query.search.trim(),
        'p_sort': query.sort.name,
        'p_after_key': after?.key,
        'p_after_id': after?.id,
        'p_limit': limit,
      },
      decode: (json) => [
        for (final r in (json as List? ?? const []))
          (customer: customerSummaryFromJson(asJsonObject(r)), key: asJsonObject(r).requireString('sort_key')),
      ],
    );
    final next = rows.length < limit ? null : (key: rows.last.key, id: rows.last.customer.id);
    return PageResult([for (final r in rows) r.customer], next: next);
  }

  Future<CustomerDetail?> detail(String id) => _api.rpc(
    'customer_detail',
    params: {'p_customer_id': id},
    decode: (json) => json == null ? null : customerDetailFromJson(asJsonObject(json)),
  );

  Future<String> insert(Map<String, Object?> columns) => _api.run(
    'customers.insert',
    () async => (await _client.from('customers').insert(columns).select('id').single()).requireString('id'),
  );

  Future<void> update(String id, Map<String, Object?> columns) => _api.run('customers.update', () async {
    final rows = await _client.from('customers').update(columns).eq('id', id).select('id');
    if (rows.isEmpty) throw const AppFailure(FailureKind.permissionDenied);
  });

  Future<void> recordAdjustment(String customerId, String kind, int amountPaise, String requestId, {String? note}) =>
      _api.rpc(
        'record_adjustment',
        params: {
          'p_customer_id': customerId,
          'p_kind': kind,
          'p_amount_paise': amountPaise,
          'p_client_request_id': requestId,
          'p_note': note,
        },
        decode: (_) {},
      );

  Future<List<RegularMaalItem>> regularMaal(String customerId, {required int limit}) => _api.rpc(
    'regular_maal',
    params: {'p_customer_id': customerId, 'p_limit': limit},
    decode: (json) => [for (final r in (json as List? ?? const [])) regularMaalFromJson(asJsonObject(r))],
  );

  Future<List<CustomerRate>> rates(String customerId) => _api.rpc(
    'customer_rates',
    params: {'p_customer_id': customerId},
    decode: (json) => [for (final r in (json as List? ?? const [])) customerRateFromJson(asJsonObject(r))],
  );

  Future<ProductRef?> findDesign(String customerId, String designNo) => _api.rpc(
    'quote_products',
    params: {
      'p_customer_id': customerId,
      'p_design_nos': [designNo.trim()],
    },
    decode: (json) {
      final rows = (json as List? ?? const []).map(asJsonObject).where((r) => r['product_id'] != null).toList();
      if (rows.isEmpty) return null;
      final r = rows.first;
      return ProductRef(
        productId: r.requireString('product_id'),
        designNo: r.requireString('design_no'),
        name: r.requireString('name'),
        defaultRate: Money.paise(r.requireInt('default_rate_paise')),
      );
    },
  );

  Future<void> upsertRate(String customerId, String productId, int ratePaise) =>
      _api.run('customer_rates.upsert', () async {
        final updated = await _client
            .from('customer_product_rates')
            .update({'rate_paise': ratePaise})
            .eq('customer_id', customerId)
            .eq('product_id', productId)
            .select('product_id');
        if (updated.isNotEmpty) return;
        await _client.from('customer_product_rates').insert({
          'customer_id': customerId,
          'product_id': productId,
          'rate_paise': ratePaise,
        });
      });

  Future<void> deleteRate(String customerId, String productId) => _api.run('customer_rates.delete', () async {
    final rows = await _client
        .from('customer_product_rates')
        .delete()
        .eq('customer_id', customerId)
        .eq('product_id', productId)
        .select('product_id');
    if (rows.isEmpty) throw const AppFailure(FailureKind.permissionDenied);
  });
}

CustomerSummary customerSummaryFromJson(Map<String, dynamic> j) => CustomerSummary(
  id: j.requireString('id'),
  name: j.requireString('name'),
  shopName: j.optionalString('shop_name'),
  city: j.optionalString('city'),
  phone: j.optionalString('phone'),
  whatsappPhone: j.optionalString('whatsapp_phone'),
  baki: switch (j.optionalInt('balance_paise')) {
    final p? => Money.paise(p),
    null => null,
  },
  lastActivityAt: j.optionalDateTime('last_activity_at'),
);

CustomerDetail customerDetailFromJson(Map<String, dynamic> j) => CustomerDetail(
  id: j.requireString('id'),
  name: j.requireString('name'),
  isArchived: j['archived'] == true,
  orderCount: j.requireInt('order_count'),
  openOrders: j.requireInt('open_orders'),
  specialRates: j.requireInt('special_rates'),
  shopName: j.optionalString('shop_name'),
  city: j.optionalString('city'),
  phone: j.optionalString('phone'),
  whatsappPhone: j.optionalString('whatsapp_phone'),
  notes: j.optionalString('notes'),
  baki: switch (j.optionalInt('balance_paise')) {
    final p? => Money.paise(p),
    null => null,
  },
  lastOrderAt: j.optionalDateTime('last_order_at'),
);

RegularMaalItem regularMaalFromJson(Map<String, dynamic> j) => RegularMaalItem(
  productId: j.requireString('product_id'),
  designNo: j.requireString('design_no'),
  name: j.requireString('name'),
  timesOrdered: j.requireInt('times_ordered'),
  lastQty: j.requireInt('last_qty'),
  rate: Money.paise(j.requireInt('rate_paise')),
  isOrderable: j['is_orderable'] == true,
  lastOrderedAt: j.optionalDateTime('last_ordered_at'),
  thumbPath: j.optionalString('thumb_path'),
);

CustomerRate customerRateFromJson(Map<String, dynamic> j) => CustomerRate(
  productId: j.requireString('product_id'),
  designNo: j.requireString('design_no'),
  name: j.requireString('name'),
  defaultRate: Money.paise(j.requireInt('default_rate_paise')),
  rate: Money.paise(j.requireInt('rate_paise')),
);

/// Columns a client may write (matches the column-level grants).
Map<String, Object?> customerColumns(CustomerDraft d) {
  String? clean(String v) => v.trim().isEmpty ? null : v.trim();
  return {
    'name': d.name.trim(),
    'shop_name': clean(d.shopName),
    'city': clean(d.city),
    'phone': CustomerDraft.normalisePhone(d.phone),
    'whatsapp_phone': CustomerDraft.normalisePhone(d.whatsappPhone),
    'notes': clean(d.notes),
  };
}
