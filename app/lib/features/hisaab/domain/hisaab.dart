import 'package:meta/meta.dart';

import '../../../core/money/money.dart';
import '../../../core/money/payment_mode.dart';
import '../../../core/state/paged.dart';

enum LedgerKind {
  opening,
  order,
  payment,
  adjustment,
  reversal;

  static LedgerKind parse(String value) =>
      values.firstWhere((k) => k.name == value, orElse: () => throw FormatException('unknown kind', value));
}

/// One line of a customer's Hisaab. Positive [amount] raises Baki (orders,
/// opening), negative lowers it (payments, reversals). Entries are
/// append-only on the server: corrections are new entries.
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.orderId,
    this.orderNo,
    this.paymentId,
    this.paymentMode,
    this.note,
  });

  final String id;
  final LedgerKind kind;
  final Money amount;
  final Money balanceAfter;
  final DateTime createdAt;
  final String? orderId;
  final int? orderNo;
  final String? paymentId;
  final PaymentMode? paymentMode;
  final String? note;
}

typedef LedgerCursor = ({DateTime createdAt, String id});

@immutable
class RecordedPayment {
  const RecordedPayment({
    required this.paymentId,
    required this.paymentNo,
    required this.amount,
    required this.balanceAfter,
    required this.replayed,
  });

  final String paymentId;
  final int paymentNo;
  final Money amount;
  final Money balanceAfter;
  final bool replayed;
}

/// Everything printed on a payment receipt — only share-safe fields.
@immutable
class PaymentReceipt {
  const PaymentReceipt({
    required this.paymentNo,
    required this.amount,
    required this.mode,
    required this.receivedAt,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.customerName,
    required this.businessName,
    this.reference,
    this.customerPhone,
    this.businessPhone,
    this.businessAddress,
    this.gstin,
  });

  final int paymentNo;
  final Money amount;
  final PaymentMode mode;
  final DateTime receivedAt;
  final Money balanceBefore;
  final Money balanceAfter;
  final String customerName;
  final String businessName;
  final String? reference;
  final String? customerPhone;
  final String? businessPhone;
  final String? businessAddress;
  final String? gstin;
}

/// Hisaab port. Implementations throw `AppFailure`.
abstract interface class HisaabRepository {
  Future<PageResult<LedgerEntry, LedgerCursor>> ledger(String customerId, {LedgerCursor? before, int limit});

  /// Idempotent on [requestId]: a retry returns the first result.
  Future<RecordedPayment> recordPayment({
    required String customerId,
    required Money amount,
    required PaymentMode mode,
    required String requestId,
    String? reference,
    String? note,
  });

  /// [amount] is signed: positive raises Baki. Adjustments need a note.
  Future<void> recordAdjustment({
    required String customerId,
    required Money amount,
    required String requestId,
    required bool opening,
    String? note,
  });

  Future<PaymentReceipt?> receipt(String paymentId);
}
