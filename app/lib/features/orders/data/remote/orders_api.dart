import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/state/paged.dart';
import '../../domain/orders.dart';
import 'orders_dto.dart';

/// Remote data source for orders. Reads are SECURITY INVOKER RPCs (RLS);
/// writes are SECURITY DEFINER RPCs that recompute every amount.
class OrdersApi {
  const OrdersApi(this._api);

  final ApiClient _api;

  Future<PageResult<OrderSummary, OrderCursor>> page(OrderQuery query, {OrderCursor? after, required int limit}) async {
    final rows = await _api.rpc(
      'order_list',
      params: {
        'p_customer_id': query.customerId,
        'p_scope': query.pendingOnly ? 'pending' : 'all',
        'p_before_at': after?.createdAt.toUtc().toIso8601String(),
        'p_before_id': after?.id,
        'p_limit': limit,
      },
      decode: (json) => [for (final r in (json as List? ?? const [])) orderSummaryFromJson(asJsonObject(r))],
    );
    final next = rows.length < limit ? null : (createdAt: rows.last.createdAt, id: rows.last.id);
    return PageResult(rows, next: next);
  }

  Future<OrderDetail?> detail(String id) => _api.rpc(
    'order_detail',
    params: {'p_order_id': id},
    decode: (json) => json == null ? null : orderDetailFromJson(asJsonObject(json)),
  );

  Future<List<QuotedProduct>> quote(String? customerId, {List<String>? productIds, List<String>? designNos}) =>
      _api.rpc(
        'quote_products',
        params: {'p_customer_id': customerId, 'p_product_ids': productIds, 'p_design_nos': designNos},
        decode: (json) => [for (final r in (json as List? ?? const [])) ?quotedProductFromJson(asJsonObject(r))],
      );

  Future<PlacedOrder> createOrder(Map<String, Object?> params) => _api.rpc(
    'create_order',
    params: params,
    decode: (json) => placedOrderFromJson(asJsonObject(json)),
    // Placing an order may take longer than a read on a slow network; the
    // request is idempotent, so a timeout is safe to retry.
    timeout: const Duration(seconds: 30),
  );

  Future<void> transition(String orderId, OrderStatus to) =>
      _api.rpc('transition_order', params: {'p_order_id': orderId, 'p_to': to.name}, decode: (_) {});

  Future<void> cancel(String orderId, String? reason) =>
      _api.rpc('cancel_order', params: {'p_order_id': orderId, 'p_reason': reason}, decode: (_) {});

  Future<List<ReorderLine>> reorderPreview(String orderId) => _api.rpc(
    'reorder_preview',
    params: {'p_order_id': orderId},
    decode: (json) => [for (final r in (json as List? ?? const [])) reorderLineFromJson(asJsonObject(r))],
  );
}
