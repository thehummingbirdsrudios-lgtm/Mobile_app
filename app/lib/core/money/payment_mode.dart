/// How money was received. Shared by orders, Hisaab and receipts.
enum PaymentMode {
  cash,
  upi,
  bank,
  cheque;

  static PaymentMode parse(String value) =>
      values.firstWhere((m) => m.name == value, orElse: () => throw FormatException('unknown mode', value));
}
