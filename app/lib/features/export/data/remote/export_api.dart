import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/export.dart';

typedef _DatedCursor = ({DateTime at, String id});

/// Remote data source: owner-only, keyset-paged export RPCs.
class ExportApi {
  const ExportApi(this._api);

  final ApiClient _api;

  static const _pageSize = 500;
  static const _ordersPerLinesPage = 200;

  Future<ExportPage> page(ExportKind kind, {ExportRange? range, Object? after}) => switch (kind) {
    ExportKind.customers => _byId('export_customers', after, _customer),
    ExportKind.designs => _byId('export_designs', after, _design),
    ExportKind.ledger => _dated('export_ledger', range!, after, _ledger),
    ExportKind.orders => _dated('export_orders', range!, after, _order),
    ExportKind.orderLines => _lines(range!, after),
  };

  Future<ExportPage> _byId(String fn, Object? after, List<Object?> Function(Map<String, dynamic>) row) async {
    final rows = await _rows(fn, {'p_after': after, 'p_limit': _pageSize});
    return ExportPage([
      for (final r in rows) row(r),
    ], next: rows.length < _pageSize ? null : rows.last.requireString('id'));
  }

  Future<ExportPage> _dated(
    String fn,
    ExportRange range,
    Object? after,
    List<Object?> Function(Map<String, dynamic>) row,
  ) async {
    final cursor = after as _DatedCursor?;
    final rows = await _rows(fn, {..._range(range, cursor), 'p_limit': _pageSize});
    return ExportPage(
      [for (final r in rows) row(r)],
      next: rows.length < _pageSize
          ? null
          : (at: rows.last.requireDateTime('created_at'), id: rows.last.requireString('id')),
    );
  }

  /// Pages by ORDER (all lines of an order arrive together).
  Future<ExportPage> _lines(ExportRange range, Object? after) async {
    final cursor = after as _DatedCursor?;
    final rows = await _rows('export_order_items', {..._range(range, cursor), 'p_limit': _ordersPerLinesPage});
    final orders = {for (final r in rows) r.requireString('order_id')};
    return ExportPage(
      [for (final r in rows) _line(r)],
      next: orders.length < _ordersPerLinesPage
          ? null
          : (at: rows.last.requireDateTime('order_created_at'), id: rows.last.requireString('order_id')),
    );
  }

  static Map<String, Object?> _range(ExportRange range, _DatedCursor? cursor) => {
    'p_from': range.from.toUtc().toIso8601String(),
    'p_to': range.to.toUtc().toIso8601String(),
    'p_after_at': cursor?.at.toUtc().toIso8601String(),
    'p_after_id': cursor?.id,
  };

  Future<List<Map<String, dynamic>>> _rows(String fn, Map<String, Object?> params) => _api.rpc(
    fn,
    params: params,
    decode: (json) => [for (final r in (json as List? ?? const [])) asJsonObject(r)],
    timeout: const Duration(seconds: 30),
  );

  static Money? _money(Map<String, dynamic> j, String key) => switch (j.optionalInt(key)) {
    final v? => Money.paise(v),
    null => null,
  };

  static Grams? _grams(Map<String, dynamic> j, String key) => switch (j.optionalInt(key)) {
    final v? => Grams(v),
    null => null,
  };

  static CodeCell? _code(Map<String, dynamic> j, String key) => switch (j.optionalString(key)) {
    final v? => CodeCell(v),
    null => null,
  };

  static List<Object?> _customer(Map<String, dynamic> j) => [
    j.requireString('name'),
    j.optionalString('shop_name'),
    j.optionalString('city'),
    j.optionalString('phone'),
    j.optionalString('whatsapp_phone'),
    Money.paise(j.requireInt('balance_paise')),
    j['archived'] == true,
    j.requireDateTime('created_at'),
  ];

  static List<Object?> _design(Map<String, dynamic> j) => [
    j.requireString('design_no'),
    j.requireString('name'),
    j.optionalString('category'),
    Money.paise(j.requireInt('rate_paise')),
    _grams(j, 'weight_mg'),
    j['is_available'] == true,
    j['archived'] == true,
    j.requireDateTime('published_at'),
    _money(j, 'cost_paise'),
    j.optionalString('supplier_name'),
  ];

  static List<Object?> _ledger(Map<String, dynamic> j) => [
    j.requireDateTime('created_at'),
    j.requireString('customer_name'),
    _code(j, 'kind'),
    Money.paise(j.requireInt('amount_paise')),
    Money.paise(j.requireInt('balance_after_paise')),
    j.optionalInt('order_no'),
    _code(j, 'payment_mode'),
    j.optionalString('payment_reference'),
    j.optionalString('note'),
  ];

  static List<Object?> _order(Map<String, dynamic> j) => [
    j.requireDateTime('created_at'),
    j.requireInt('order_no'),
    j.requireString('customer_name'),
    _code(j, 'status'),
    j.requireInt('total_qty'),
    Money.paise(j.requireInt('total_paise')),
    _grams(j, 'total_weight_mg'),
    j.optionalString('note'),
  ];

  static List<Object?> _line(Map<String, dynamic> j) => [
    j.requireDateTime('order_created_at'),
    j.requireInt('order_no'),
    j.requireString('customer_name'),
    j.requireInt('line_no'),
    j.requireString('design_no'),
    j.requireString('product_name'),
    j.requireInt('qty'),
    Money.paise(j.requireInt('rate_paise')),
    Money.paise(j.requireInt('amount_paise')),
    _grams(j, 'weight_mg'),
  ];
}
