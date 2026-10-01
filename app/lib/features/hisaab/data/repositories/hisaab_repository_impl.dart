import '../../../../core/money/money.dart';
import '../../../../core/money/payment_mode.dart';
import '../../../../core/state/paged.dart';
import '../../domain/hisaab.dart';
import '../remote/hisaab_api.dart';

class HisaabRepositoryImpl implements HisaabRepository {
  const HisaabRepositoryImpl(this._remote);

  final HisaabApi _remote;

  static String? _clean(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();

  @override
  Future<PageResult<LedgerEntry, LedgerCursor>> ledger(String customerId, {LedgerCursor? before, int limit = 50}) =>
      _remote.ledger(customerId, before: before, limit: limit);

  @override
  Future<RecordedPayment> recordPayment({
    required String customerId,
    required Money amount,
    required PaymentMode mode,
    required String requestId,
    String? reference,
    String? note,
  }) => _remote.recordPayment({
    'p_customer_id': customerId,
    'p_amount_paise': amount.paise,
    'p_mode': mode.name,
    'p_client_request_id': requestId,
    'p_reference': _clean(reference),
    'p_note': _clean(note),
  });

  @override
  Future<void> recordAdjustment({
    required String customerId,
    required Money amount,
    required String requestId,
    required bool opening,
    String? note,
  }) => _remote.recordAdjustment({
    'p_customer_id': customerId,
    'p_kind': opening ? 'opening' : 'adjustment',
    'p_amount_paise': amount.paise,
    'p_client_request_id': requestId,
    'p_note': _clean(note),
  });

  @override
  Future<PaymentReceipt?> receipt(String paymentId) => _remote.receipt(paymentId);
}
