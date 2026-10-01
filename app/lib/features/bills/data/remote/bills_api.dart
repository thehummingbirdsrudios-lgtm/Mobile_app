import '../../../../core/errors/app_failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/bills.dart';

class BillsApi {
  const BillsApi(this._api);

  final ApiClient _api;

  Future<IssuedBill> issue(String orderId) => _api.rpc(
    'issue_bill',
    params: {'p_order_id': orderId},
    decode: (json) {
      final j = asJsonObject(json);
      return IssuedBill(
        billId: j.requireString('bill_id'),
        billNo: j.requireInt('bill_no'),
        replayed: j['replayed'] == true,
      );
    },
  );

  Future<BillDocument?> document(String billId) async {
    try {
      return await _api.rpc(
        'bill_payload',
        params: {'p_bill_id': billId},
        decode: (json) => billDocumentFromJson(asJsonObject(json)),
      );
    } on AppFailure catch (f) {
      if (f.kind == FailureKind.notFound) return null; // bill_not_found (or hidden by RLS)
      rethrow;
    }
  }
}

BillDocument billDocumentFromJson(Map<String, dynamic> j) {
  final b = asJsonObject(j['business'] ?? const <String, dynamic>{});
  return BillDocument(
    billNo: j.requireInt('bill_no'),
    issuedAt: j.requireDateTime('issued_at'),
    orderNo: j.requireInt('order_no'),
    customerName: j.requireString('customer_name'),
    customerPhone: j.optionalString('customer_phone'),
    business: BillBusiness(
      name: b.optionalString('business_name') ?? '',
      phone: b.optionalString('phone'),
      whatsappPhone: b.optionalString('whatsapp_phone'),
      address: b.optionalString('address'),
      gstin: b.optionalString('gstin'),
      footer: b.optionalString('bill_footer'),
      logoPath: b.optionalString('logo_path'),
      watermark: b['watermark_enabled'] == true,
    ),
    totalQty: j.requireInt('total_qty'),
    total: Money.paise(j.requireInt('total_paise')),
    totalWeightMg: j.optionalInt('total_weight_mg'),
    paid: Money.paise(j.requireInt('paid_paise')),
    balanceAfter: Money.paise(j.requireInt('balance_after_paise')),
    items: [
      for (final raw in (j['items'] as List? ?? const []))
        if (asJsonObject(raw) case final i)
          BillItem(
            designNo: i.requireString('design_no'),
            name: i.requireString('name'),
            qty: i.requireInt('qty'),
            rate: Money.paise(i.requireInt('rate_paise')),
            amount: Money.paise(i.requireInt('amount_paise')),
            weightMg: i.optionalInt('weight_mg'),
            thumbPath: i.optionalString('thumb_path'),
          ),
    ],
  );
}
