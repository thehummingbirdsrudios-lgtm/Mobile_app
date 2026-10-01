import 'package:intl/intl.dart';

import '../money/money.dart';

/// Locale-aware display formatting. Storage is always UTC; display uses the
/// device locale and Indian conventions (dd MMM, Indian digit grouping).
abstract final class AppFormat {
  /// "01 Oct" in the current language.
  static String shortDate(DateTime value, String locale) => DateFormat('dd MMM', locale).format(value.toLocal());

  /// "01 Oct 2026" — used on bills and receipts where the year matters.
  static String fullDate(DateTime value, String locale) => DateFormat('dd MMM yyyy', locale).format(value.toLocal());

  /// "01 Oct 2026, 4:05 PM"
  static String dateTime(DateTime value, String locale) =>
      DateFormat('dd MMM yyyy, h:mm a', locale).format(value.toLocal());

  /// Indian-grouped integer: 1,20,000.
  static String count(int value) => Money.groupIndian(value);

  /// Parses user weight input in grams ("42", "4.25", "1,250.5") into
  /// milligrams. Null for empty/invalid input or more than 3 decimals.
  static int? parseGramsToMg(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    final m = RegExp(r'^(\d{1,6})(?:\.(\d{1,3}))?$').firstMatch(cleaned);
    if (m == null) return null;
    final mg = int.parse(m.group(1)!) * 1000 + int.parse((m.group(2) ?? '').padRight(3, '0'));
    return mg == 0 ? null : mg;
  }

  /// Grams for an input field (no unit, no grouping): 4250 → "4.25".
  static String gramsInput(int milligrams) {
    final whole = milligrams ~/ 1000;
    final rest = milligrams % 1000;
    if (rest == 0) return '$whole';
    return '$whole.${rest.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
  }

  /// Weight stored in milligrams, shown in grams with up to 3 decimals: "42 g", "4.25 g".
  static String grams(int milligrams) {
    final whole = milligrams ~/ 1000;
    final rest = milligrams % 1000;
    if (rest == 0) return '${Money.groupIndian(whole)} g';
    final decimals = rest.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '');
    return '${Money.groupIndian(whole)}.$decimals g';
  }
}
