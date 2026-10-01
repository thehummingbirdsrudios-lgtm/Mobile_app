import 'package:meta/meta.dart';

import '../../../core/money/money.dart';

@immutable
class IssuedBill {
  const IssuedBill({required this.billId, required this.billNo, required this.replayed});

  final String billId;
  final int billNo;

  /// The order already had a bill; this is that same bill.
  final bool replayed;
}

/// Business details frozen on the bill when it was issued.
@immutable
class BillBusiness {
  const BillBusiness({
    required this.name,
    this.phone,
    this.whatsappPhone,
    this.address,
    this.gstin,
    this.footer,
    this.logoPath,
    this.watermark = false,
  });

  final String name;
  final String? phone;
  final String? whatsappPhone;
  final String? address;
  final String? gstin;
  final String? footer;
  final String? logoPath;
  final bool watermark;
}

@immutable
class BillItem {
  const BillItem({
    required this.designNo,
    required this.name,
    required this.qty,
    required this.rate,
    required this.amount,
    this.weightMg,
    this.thumbPath,
  });

  final String designNo;
  final String name;
  final int qty;
  final Money rate;
  final Money amount;
  final int? weightMg;
  final String? thumbPath;
}

/// Everything printed on a bill, from `bill_payload` (share-safe fields
/// only: no cost, supplier, notes or other customers' data).
@immutable
class BillDocument {
  const BillDocument({
    required this.billNo,
    required this.issuedAt,
    required this.orderNo,
    required this.customerName,
    required this.business,
    required this.totalQty,
    required this.total,
    required this.paid,
    required this.balanceAfter,
    required this.items,
    this.customerPhone,
    this.totalWeightMg,
  });

  final int billNo;
  final DateTime issuedAt;
  final int orderNo;
  final String customerName;
  final String? customerPhone;
  final BillBusiness business;
  final int totalQty;
  final Money total;
  final int? totalWeightMg;
  final Money paid;
  final Money balanceAfter;
  final List<BillItem> items;
}

/// Bills port. Implementations throw `AppFailure`.
abstract interface class BillsRepository {
  /// Issues the order's bill (idempotent: one bill per order).
  Future<IssuedBill> issue(String orderId);

  Future<BillDocument?> document(String billId);
}
