import 'package:meta/meta.dart';

import '../../../core/money/money.dart';
import '../../../core/state/paged.dart';

enum OrderStatus {
  confirmed,
  processing,
  ready,
  completed,
  cancelled;

  /// Not yet completed or cancelled.
  bool get isOpen => this == confirmed || this == processing || this == ready;

  /// Next steps a manager may take (mirrors app.order_transitions).
  List<OrderStatus> get forward => switch (this) {
    confirmed => const [processing, ready, completed],
    processing => const [ready],
    ready => const [completed],
    completed || cancelled => const [],
  };

  bool get canCancel => isOpen;

  static OrderStatus parse(String value) =>
      values.firstWhere((s) => s.name == value, orElse: () => throw FormatException('unknown status', value));
}

enum PaymentMode {
  cash,
  upi,
  bank,
  cheque;

  static PaymentMode parse(String value) =>
      values.firstWhere((m) => m.name == value, orElse: () => throw FormatException('unknown mode', value));
}

@immutable
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNo,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.totalQty,
    required this.total,
    required this.createdAt,
    this.billId,
  });

  final String id;
  final int orderNo;
  final String customerId;
  final String customerName;
  final OrderStatus status;
  final int totalQty;
  final Money total;
  final DateTime createdAt;
  final String? billId;
}

typedef OrderCursor = ({DateTime createdAt, String id});

@immutable
class OrderQuery {
  const OrderQuery({this.customerId, this.pendingOnly = false});

  final String? customerId;
  final bool pendingOnly;

  @override
  bool operator ==(Object other) =>
      other is OrderQuery && other.customerId == customerId && other.pendingOnly == pendingOnly;

  @override
  int get hashCode => Object.hash(customerId, pendingOnly);
}

/// A confirmed order line: an immutable snapshot taken when ordered.
@immutable
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.designNo,
    required this.name,
    required this.rate,
    required this.qty,
    required this.amount,
    this.thumbPath,
    this.weightMg,
  });

  final String productId;
  final String designNo;
  final String name;
  final Money rate;
  final int qty;
  final Money amount;
  final String? thumbPath;
  final int? weightMg;
}

@immutable
class OrderCustomer {
  const OrderCustomer({required this.id, required this.name, this.phone, this.whatsappPhone, this.city});

  final String id;
  final String name;
  final String? phone;
  final String? whatsappPhone;
  final String? city;
}

@immutable
class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.paymentNo,
    required this.amount,
    required this.mode,
    required this.receivedAt,
  });

  final String id;
  final int paymentNo;
  final Money amount;
  final PaymentMode mode;
  final DateTime receivedAt;
}

@immutable
class OrderBillRef {
  const OrderBillRef({required this.id, required this.billNo, required this.issuedAt});

  final String id;
  final int billNo;
  final DateTime issuedAt;
}

@immutable
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.totalQty,
    required this.total,
    required this.createdAt,
    required this.customer,
    required this.items,
    this.payments = const [],
    this.totalWeightMg,
    this.note,
    this.reorderOf,
    this.cancelReason,
    this.createdByName,
    this.bill,
  });

  final String id;
  final int orderNo;
  final OrderStatus status;
  final int totalQty;
  final Money total;
  final DateTime createdAt;
  final OrderCustomer customer;
  final List<OrderLine> items;

  /// Empty when the member may not see payments (server RLS).
  final List<OrderPayment> payments;
  final int? totalWeightMg;
  final String? note;
  final String? reorderOf;
  final String? cancelReason;
  final String? createdByName;
  final OrderBillRef? bill;
}

/// A design priced for one customer today (rate = special rate if any).
@immutable
class QuotedProduct {
  const QuotedProduct({
    required this.productId,
    required this.designNo,
    required this.name,
    required this.rate,
    required this.isOrderable,
    this.defaultRate,
    this.weightMg,
    this.thumbPath,
  });

  final String productId;
  final String designNo;
  final String name;
  final Money rate;
  final Money? defaultRate;
  final bool isOrderable;
  final int? weightMg;
  final String? thumbPath;

  bool get hasSpecialRate => defaultRate != null && defaultRate != rate;
}

/// One line the user wants to order. [rate] is what the user saw; the server
/// rejects the order if it no longer matches (`rate_changed`).
@immutable
class OrderRequestLine {
  const OrderRequestLine({required this.productId, required this.qty, required this.expectedRate});

  final String productId;
  final int qty;
  final Money expectedRate;
}

@immutable
class PaymentInput {
  const PaymentInput({required this.amount, required this.mode, this.reference});

  final Money amount;
  final PaymentMode mode;
  final String? reference;
}

@immutable
class PlacedPayment {
  const PlacedPayment({required this.paymentId, required this.paymentNo, required this.amount, this.balanceAfter});

  final String paymentId;
  final int paymentNo;
  final Money amount;
  final Money? balanceAfter;
}

/// The server's answer to create_order. [replayed] means this request had
/// already succeeded earlier (a retry after a lost response).
@immutable
class PlacedOrder {
  const PlacedOrder({
    required this.orderId,
    required this.orderNo,
    required this.customerId,
    required this.totalQty,
    required this.total,
    required this.replayed,
    this.payment,
  });

  final String orderId;
  final int orderNo;
  final String customerId;
  final int totalQty;
  final Money total;
  final bool replayed;
  final PlacedPayment? payment;
}

/// `rate_changed`: the rates now in force, per product.
typedef RateUpdate = ({String productId, Money rate});

/// Fari Order preview line: the old order's line with TODAY's rate.
@immutable
class ReorderLine {
  const ReorderLine({
    required this.productId,
    required this.designNo,
    required this.name,
    required this.qty,
    required this.oldRate,
    required this.rate,
    required this.isOrderable,
    this.thumbPath,
  });

  final String productId;
  final String designNo;
  final String name;
  final int qty;
  final Money oldRate;
  final Money rate;
  final bool isOrderable;
  final String? thumbPath;

  bool get rateChanged => oldRate != rate;
}

/// Orders port. Implementations throw `AppFailure`.
abstract interface class OrdersRepository {
  Future<PageResult<OrderSummary, OrderCursor>> page(OrderQuery query, {OrderCursor? after, int limit});

  Future<OrderDetail?> detail(String orderId);

  /// Prices designs for [customerId] (by id or by design number). Without a
  /// customer, normal rates. Unknown design numbers are simply absent.
  Future<List<QuotedProduct>> quote(String? customerId, {List<String> productIds, List<String> designNos});

  Future<PlacedOrder> place({
    required String customerId,
    required List<OrderRequestLine> lines,
    required String requestId,
    String? note,
    String? reorderOf,
    PaymentInput? payment,
  });

  Future<void> transition(String orderId, OrderStatus to);

  Future<void> cancel(String orderId, {String? reason});

  Future<List<ReorderLine>> reorderPreview(String orderId);
}

/// A line in the cart (device-local until the order is placed).
@immutable
class CartLine {
  const CartLine({
    required this.productId,
    required this.designNo,
    required this.name,
    required this.rate,
    required this.qty,
    this.isOrderable = true,
    this.defaultRate,
    this.weightMg,
    this.thumbPath,
  });

  factory CartLine.fromQuote(QuotedProduct q, int qty) => CartLine(
    productId: q.productId,
    designNo: q.designNo,
    name: q.name,
    rate: q.rate,
    qty: qty,
    isOrderable: q.isOrderable,
    defaultRate: q.defaultRate,
    weightMg: q.weightMg,
    thumbPath: q.thumbPath,
  );

  final String productId;
  final String designNo;
  final String name;
  final Money rate;
  final int qty;
  final bool isOrderable;
  final Money? defaultRate;
  final int? weightMg;
  final String? thumbPath;

  Money get amount => rate.times(qty);
  bool get hasSpecialRate => defaultRate != null && defaultRate != rate;

  CartLine copyWith({Money? rate, int? qty, bool? isOrderable, Money? defaultRate}) => CartLine(
    productId: productId,
    designNo: designNo,
    name: name,
    rate: rate ?? this.rate,
    qty: qty ?? this.qty,
    isOrderable: isOrderable ?? this.isOrderable,
    defaultRate: defaultRate ?? this.defaultRate,
    weightMg: weightMg,
    thumbPath: thumbPath,
  );
}

/// Limits mirrored from create_order (server re-checks).
abstract final class OrderLimits {
  static const maxLines = 200;
  static const maxQty = 100000;
  static const maxNote = 1000;
}

/// The order being built. [requestId] identifies this exact intent: retrying
/// an unchanged cart reuses it (the server returns the first result), any
/// change makes a new one.
@immutable
class CartDraft {
  const CartDraft({
    required this.requestId,
    this.customerId,
    this.customerName,
    this.lines = const [],
    this.note = '',
    this.reorderOf,
  });

  final String requestId;
  final String? customerId;
  final String? customerName;
  final List<CartLine> lines;
  final String note;

  /// Set when this cart was started from "Fari Order".
  final String? reorderOf;

  bool get isEmpty => lines.isEmpty;
  int get totalQty => lines.fold(0, (sum, l) => sum + l.qty);
  Money get total => lines.fold(Money.zero, (sum, l) => sum + l.amount);
  bool get hasUnavailable => lines.any((l) => !l.isOrderable);

  /// Null when any line has no weight (a partial total would mislead).
  int? get totalWeightMg =>
      lines.any((l) => l.weightMg == null) ? null : lines.fold<int>(0, (sum, l) => sum + l.weightMg! * l.qty);

  bool get canPlace => customerId != null && lines.isNotEmpty && !hasUnavailable;

  CartDraft copyWith({
    required String requestId,
    String? customerId,
    String? customerName,
    List<CartLine>? lines,
    String? note,
    String? reorderOf,
    bool clearReorder = false,
  }) => CartDraft(
    requestId: requestId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    lines: lines ?? this.lines,
    note: note ?? this.note,
    reorderOf: clearReorder ? null : (reorderOf ?? this.reorderOf),
  );
}

/// Device-local cart persistence, one draft per signed-in identity.
abstract interface class CartDraftStore {
  CartDraft? read(String scope);

  Future<void> write(String scope, CartDraft? draft);
}

/// `rate_changed` details → the rates now in force.
List<RateUpdate> rateUpdatesFromDetails(Object? details) => [
  if (details is List)
    for (final raw in details)
      if (raw is Map && raw['product_id'] is String && raw['rate_paise'] is num)
        (productId: raw['product_id'] as String, rate: Money.paise((raw['rate_paise'] as num).toInt())),
];

/// `product_unavailable` details → affected product ids.
Set<String> unavailableFromDetails(Object? details) => {
  if (details is List)
    for (final raw in details)
      if (raw is Map && raw['product_id'] is String) raw['product_id'] as String,
};
