import 'package:flutter/foundation.dart';

/// Indian rupee amount held as integer paise. Never use double for money.
///
/// The server is authoritative for every total (create_order / bills); this
/// type exists for display and for client-side previews that are always
/// re-validated by the server.
@immutable
final class Money implements Comparable<Money> {
  const Money.paise(this.paise);

  /// Parses user input like "620", "620.5", "1,20,000.75" into paise.
  /// Returns null for anything that is not a valid non-negative amount
  /// with at most two decimals.
  static Money? tryParseRupees(String input) {
    final cleaned = input.replaceAll(',', '').replaceAll('₹', '').trim();
    final match = RegExp(r'^(\d{1,13})(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final rupees = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    final paise = rupees * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
    return paise > maxPaise ? null : Money.paise(paise);
  }

  /// Largest amount the backend accepts for a single total (₹1,00,00,00,00,000 = ₹10,000 crore).
  static const maxPaise = 10000000000000;
  static const zero = Money.paise(0);

  final int paise;

  bool get isZero => paise == 0;
  bool get isNegative => paise < 0;

  Money operator +(Money other) => Money.paise(paise + other.paise);
  Money operator -(Money other) => Money.paise(paise - other.paise);
  Money operator -() => Money.paise(-paise);

  /// Rate × quantity. Quantity is whole pieces.
  Money times(int quantity) => Money.paise(paise * quantity);

  static Money sum(Iterable<Money> values) => values.fold(zero, (a, b) => a + b);

  /// Indian grouping: ₹4,82,000 · ₹1,20,000.50 · −₹500. Paise shown only when non-zero.
  String format({bool symbol = true}) {
    final negative = paise < 0;
    final abs = paise.abs();
    final rupees = abs ~/ 100;
    final fraction = abs % 100;
    final grouped = groupIndian(rupees);
    final body = fraction == 0 ? grouped : '$grouped.${fraction.toString().padLeft(2, '0')}';
    return '${negative ? '−' : ''}${symbol ? '₹' : ''}$body';
  }

  /// Groups digits the Indian way: last three, then pairs (12,34,56,789).
  static String groupIndian(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return (value < 0 ? '-' : '') + digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final pairs = <String>[];
    while (rest.length > 2) {
      pairs.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) pairs.insert(0, rest);
    return '${value < 0 ? '-' : ''}${pairs.join(',')},$last3';
  }

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => format();
}
