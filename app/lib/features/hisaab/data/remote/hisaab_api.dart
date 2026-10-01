import '../../../../core/money/money.dart';
import '../../../../core/money/payment_mode.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/state/paged.dart';
import '../../domain/hisaab.dart';

/// Remote data source for Hisaab: ledger_page / payment_receipt (invoker,
/// RLS) and record_payment / record_adjustment (definer, idempotent).
class HisaabApi {
  const HisaabApi(this._api);

  final ApiClient _api;

  Future<PageResult<LedgerEntry, LedgerCursor>> ledger(
    String customerId, {
    LedgerCursor? before,
    required int limit,
  }) async {
    final rows = await _api.rpc(
      'ledger_page',
      params: {
        'p_customer_id': customerId,
        'p_before_at': before?.createdAt.toUtc().toIso8601String(),
        'p_before_id': before?.id,
        'p_limit': limit,
      },
      decode: (json) => [for (final r in (json as List? ?? const [])) ledgerEntryFromJson(asJsonObject(r))],
    );
    final next = rows.length < limit ? null : (createdAt: rows.last.createdAt, id: rows.last.id);
    return PageResult(rows, next: next);
  }

  Future<RecordedPayment> recordPayment(Map<String, Object?> params) => _api.rpc(
    'record_payment',
    params: params,
    decode: (json) => recordedPaymentFromJson(asJsonObject(json)),
    timeout: const Duration(seconds: 30),
  );

  Future<void> recordAdjustment(Map<String, Object?> params) =>
      _api.rpc('record_adjustment', params: params, decode: (_) {});

  Future<PaymentReceipt?> receipt(String paymentId) => _api.rpc(
    'payment_receipt',
    params: {'p_payment_id': paymentId},
    decode: (json) => json == null ? null : paymentReceiptFromJson(asJsonObject(json)),
  );
}

LedgerEntry ledgerEntryFromJson(Map<String, dynamic> j) => LedgerEntry(
  id: j.requireString('id'),
  kind: LedgerKind.parse(j.requireString('kind')),
  amount: Money.paise(j.requireInt('amount_paise')),
  balanceAfter: Money.paise(j.requireInt('balance_after_paise')),
  createdAt: j.requireDateTime('created_at'),
  orderId: j.optionalString('order_id'),
  orderNo: j.optionalInt('order_no'),
  paymentId: j.optionalString('payment_id'),
  paymentMode: switch (j.optionalString('payment_mode')) {
    final m? => PaymentMode.parse(m),
    null => null,
  },
  note: j.optionalString('note'),
);

RecordedPayment recordedPaymentFromJson(Map<String, dynamic> j) => RecordedPayment(
  paymentId: j.requireString('payment_id'),
  paymentNo: j.requireInt('payment_no'),
  amount: Money.paise(j.requireInt('amount_paise')),
  balanceAfter: Money.paise(j.requireInt('balance_after_paise')),
  replayed: j['replayed'] == true,
);

PaymentReceipt paymentReceiptFromJson(Map<String, dynamic> j) => PaymentReceipt(
  paymentNo: j.requireInt('payment_no'),
  amount: Money.paise(j.requireInt('amount_paise')),
  mode: PaymentMode.parse(j.requireString('mode')),
  receivedAt: j.requireDateTime('received_at'),
  balanceBefore: Money.paise(j.requireInt('balance_before_paise')),
  balanceAfter: Money.paise(j.requireInt('balance_after_paise')),
  customerName: j.requireString('customer_name'),
  businessName: j.requireString('business_name'),
  reference: j.optionalString('reference'),
  customerPhone: j.optionalString('customer_phone'),
  businessPhone: j.optionalString('business_phone'),
  businessAddress: j.optionalString('business_address'),
  gstin: j.optionalString('gstin'),
);
