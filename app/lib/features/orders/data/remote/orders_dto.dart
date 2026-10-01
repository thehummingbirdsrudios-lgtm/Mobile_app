import '../../../../core/money/money.dart';
import '../../../../core/money/payment_mode.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/orders.dart';

Money _money(Map<String, dynamic> j, String key) => Money.paise(j.requireInt(key));

OrderSummary orderSummaryFromJson(Map<String, dynamic> j) => OrderSummary(
  id: j.requireString('id'),
  orderNo: j.requireInt('order_no'),
  customerId: j.requireString('customer_id'),
  customerName: j.requireString('customer_name'),
  status: OrderStatus.parse(j.requireString('status')),
  totalQty: j.requireInt('total_qty'),
  total: _money(j, 'total_paise'),
  createdAt: j.requireDateTime('created_at'),
  billId: j.optionalString('bill_id'),
);

OrderDetail orderDetailFromJson(Map<String, dynamic> j) {
  final customer = asJsonObject(j['customer']);
  final bill = j['bill'] == null ? null : asJsonObject(j['bill']);
  return OrderDetail(
    id: j.requireString('id'),
    orderNo: j.requireInt('order_no'),
    status: OrderStatus.parse(j.requireString('status')),
    totalQty: j.requireInt('total_qty'),
    total: _money(j, 'total_paise'),
    createdAt: j.requireDateTime('created_at'),
    totalWeightMg: j.optionalInt('total_weight_mg'),
    note: j.optionalString('note'),
    reorderOf: j.optionalString('reorder_of'),
    cancelReason: j.optionalString('cancel_reason'),
    createdByName: j.optionalString('created_by_name'),
    customer: OrderCustomer(
      id: customer.requireString('id'),
      name: customer.requireString('name'),
      phone: customer.optionalString('phone'),
      whatsappPhone: customer.optionalString('whatsapp_phone'),
      city: customer.optionalString('city'),
    ),
    items: [
      for (final raw in (j['items'] as List? ?? const []))
        if (asJsonObject(raw) case final i)
          OrderLine(
            productId: i.requireString('product_id'),
            designNo: i.requireString('design_no'),
            name: i.requireString('name'),
            rate: _money(i, 'rate_paise'),
            qty: i.requireInt('qty'),
            amount: _money(i, 'amount_paise'),
            thumbPath: i.optionalString('thumb_path'),
            weightMg: i.optionalInt('weight_mg'),
          ),
    ],
    payments: [
      for (final raw in (j['payments'] as List? ?? const []))
        if (asJsonObject(raw) case final p)
          OrderPayment(
            id: p.requireString('id'),
            paymentNo: p.requireInt('payment_no'),
            amount: _money(p, 'amount_paise'),
            mode: PaymentMode.parse(p.requireString('mode')),
            receivedAt: p.requireDateTime('received_at'),
          ),
    ],
    bill: bill == null
        ? null
        : OrderBillRef(
            id: bill.requireString('id'),
            billNo: bill.requireInt('bill_no'),
            issuedAt: bill.requireDateTime('issued_at'),
          ),
  );
}

QuotedProduct? quotedProductFromJson(Map<String, dynamic> j) {
  if (j['product_id'] == null) return null; // unknown design number
  return QuotedProduct(
    productId: j.requireString('product_id'),
    designNo: j.requireString('design_no'),
    name: j.requireString('name'),
    rate: _money(j, 'rate_paise'),
    defaultRate: switch (j.optionalInt('default_rate_paise')) {
      final p? => Money.paise(p),
      null => null,
    },
    isOrderable: j['is_orderable'] == true,
    weightMg: j.optionalInt('weight_mg'),
    thumbPath: j.optionalString('thumb_path'),
  );
}

PlacedOrder placedOrderFromJson(Map<String, dynamic> j) {
  final p = j['payment'] == null ? null : asJsonObject(j['payment']);
  return PlacedOrder(
    orderId: j.requireString('order_id'),
    orderNo: j.requireInt('order_no'),
    customerId: j.requireString('customer_id'),
    totalQty: j.requireInt('total_qty'),
    total: _money(j, 'total_paise'),
    replayed: j['replayed'] == true,
    payment: p == null
        ? null
        : PlacedPayment(
            paymentId: p.requireString('payment_id'),
            paymentNo: p.requireInt('payment_no'),
            amount: _money(p, 'amount_paise'),
            balanceAfter: switch (p.optionalInt('balance_after_paise')) {
              final b? => Money.paise(b),
              null => null,
            },
          ),
  );
}

ReorderLine reorderLineFromJson(Map<String, dynamic> j) => ReorderLine(
  productId: j.requireString('product_id'),
  designNo: j.requireString('design_no'),
  name: j.requireString('name'),
  qty: j.requireInt('qty'),
  oldRate: _money(j, 'old_rate_paise'),
  rate: _money(j, 'rate_paise'),
  isOrderable: j['is_orderable'] == true,
  thumbPath: j.optionalString('thumb_path'),
);
