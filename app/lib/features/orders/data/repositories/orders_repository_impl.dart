import '../../../../core/state/paged.dart';
import '../../domain/orders.dart';
import '../remote/orders_api.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._remote);

  final OrdersApi _remote;

  @override
  Future<PageResult<OrderSummary, OrderCursor>> page(OrderQuery query, {OrderCursor? after, int limit = 30}) =>
      _remote.page(query, after: after, limit: limit);

  @override
  Future<OrderDetail?> detail(String orderId) => _remote.detail(orderId);

  @override
  Future<List<QuotedProduct>> quote(
    String? customerId, {
    List<String> productIds = const [],
    List<String> designNos = const [],
  }) {
    if (productIds.isEmpty && designNos.isEmpty) return Future.value(const []);
    return _remote.quote(
      customerId,
      productIds: productIds.isEmpty ? null : productIds,
      designNos: designNos.isEmpty ? null : designNos,
    );
  }

  @override
  Future<PlacedOrder> place({
    required String customerId,
    required List<OrderRequestLine> lines,
    required String requestId,
    String? note,
    String? reorderOf,
    PaymentInput? payment,
  }) => _remote.createOrder({
    'p_customer_id': customerId,
    'p_items': [
      for (final l in lines) {'product_id': l.productId, 'qty': l.qty, 'expected_rate_paise': l.expectedRate.paise},
    ],
    'p_client_request_id': requestId,
    'p_note': (note ?? '').trim().isEmpty ? null : note!.trim(),
    'p_reorder_of': reorderOf,
    'p_payment': payment == null
        ? null
        : {
            'amount_paise': payment.amount.paise,
            'mode': payment.mode.name,
            'reference': (payment.reference ?? '').trim().isEmpty ? null : payment.reference!.trim(),
          },
  });

  @override
  Future<void> transition(String orderId, OrderStatus to) => _remote.transition(orderId, to);

  @override
  Future<void> cancel(String orderId, {String? reason}) =>
      _remote.cancel(orderId, (reason ?? '').trim().isEmpty ? null : reason!.trim());

  @override
  Future<List<ReorderLine>> reorderPreview(String orderId) => _remote.reorderPreview(orderId);
}
