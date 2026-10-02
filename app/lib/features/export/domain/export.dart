import 'package:meta/meta.dart';

/// What the owner can export. Dated kinds take a period.
enum ExportKind {
  customers,
  designs,
  ledger,
  orders,
  orderLines;

  bool get isDated => this == ledger || this == orders || this == orderLines;

  /// Columns, in file order. Headers are localised by the screen.
  List<ExportColumn> get columns => switch (this) {
    customers => const [
      ExportColumn.customer,
      ExportColumn.shopName,
      ExportColumn.city,
      ExportColumn.phone,
      ExportColumn.whatsapp,
      ExportColumn.baki,
      ExportColumn.archived,
      ExportColumn.createdAt,
    ],
    designs => const [
      ExportColumn.designNo,
      ExportColumn.productName,
      ExportColumn.category,
      ExportColumn.rate,
      ExportColumn.weight,
      ExportColumn.available,
      ExportColumn.archived,
      ExportColumn.publishedAt,
      ExportColumn.cost,
      ExportColumn.supplier,
    ],
    ledger => const [
      ExportColumn.date,
      ExportColumn.customer,
      ExportColumn.entryKind,
      ExportColumn.amount,
      ExportColumn.balanceAfter,
      ExportColumn.orderNo,
      ExportColumn.paymentMode,
      ExportColumn.reference,
      ExportColumn.note,
    ],
    orders => const [
      ExportColumn.date,
      ExportColumn.orderNo,
      ExportColumn.customer,
      ExportColumn.status,
      ExportColumn.totalQty,
      ExportColumn.total,
      ExportColumn.weight,
      ExportColumn.note,
    ],
    orderLines => const [
      ExportColumn.date,
      ExportColumn.orderNo,
      ExportColumn.customer,
      ExportColumn.lineNo,
      ExportColumn.designNo,
      ExportColumn.productName,
      ExportColumn.qty,
      ExportColumn.rate,
      ExportColumn.amount,
      ExportColumn.weight,
    ],
  };
}

enum ExportColumn {
  customer,
  shopName,
  city,
  phone,
  whatsapp,
  baki,
  archived,
  createdAt,
  designNo,
  productName,
  category,
  rate,
  weight,
  available,
  publishedAt,
  cost,
  supplier,
  date,
  entryKind,
  amount,
  balanceAfter,
  orderNo,
  paymentMode,
  reference,
  note,
  status,
  totalQty,
  total,
  lineNo,
  qty,
}

/// A weight cell (stored as integer milligrams; written as grams).
@immutable
class Grams {
  const Grams(this.milligrams);

  final int milligrams;

  @override
  bool operator ==(Object other) => other is Grams && other.milligrams == milligrams;

  @override
  int get hashCode => milligrams.hashCode;
}

/// A server code (status, ledger kind, payment mode) written in the user's
/// language when a label is known.
@immutable
class CodeCell {
  const CodeCell(this.code);

  final String code;

  @override
  bool operator ==(Object other) => other is CodeCell && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// A half-open period [from, to) in the device's time zone.
typedef ExportRange = ({DateTime from, DateTime to});

enum ExportPeriod {
  thisMonth,
  lastMonth,
  last3Months,
  thisYear;

  ExportRange rangeAt(DateTime now) {
    final local = now.toLocal();
    final monthStart = DateTime(local.year, local.month);
    final nextMonth = DateTime(local.year, local.month + 1);
    return switch (this) {
      thisMonth => (from: monthStart, to: nextMonth),
      lastMonth => (from: DateTime(local.year, local.month - 1), to: monthStart),
      last3Months => (from: DateTime(local.year, local.month - 2), to: nextMonth),
      thisYear => (from: DateTime(local.year), to: DateTime(local.year + 1)),
    };
  }
}

/// One page of rows; each row matches [ExportKind.columns]. Cells are
/// String, int, Money, Grams, CodeCell, DateTime, bool or null.
@immutable
class ExportPage {
  const ExportPage(this.rows, {this.next});

  final List<List<Object?>> rows;

  /// Opaque keyset cursor for the next page; null when this was the last.
  final Object? next;
}

/// Export port (owner-only on the server). Implementations throw `AppFailure`.
abstract interface class ExportRepository {
  Future<ExportPage> page(ExportKind kind, {ExportRange? range, Object? after});
}
