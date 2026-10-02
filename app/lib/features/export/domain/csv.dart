import '../../../core/money/money.dart';
import 'export.dart';

/// What the encoder needs besides the rows. Plain data, so it can be sent to
/// a background isolate.
typedef CsvOptions = ({
  List<String> header,
  List<List<Object?>> rows,
  String yes,
  String no,
  Map<String, String> labels,
});

/// RFC 4180 CSV for spreadsheet apps:
/// - UTF-8 with a byte-order mark so Excel shows Gujarati/Hindi correctly,
/// - CRLF line endings, quoting only where needed,
/// - text that a spreadsheet would run as a formula (= + - @ tab CR) is
///   prefixed with an apostrophe (CSV injection); numbers are never touched,
/// - money as plain rupees with two decimals (12345.50), weights as grams
///   with three decimals, dates as local "yyyy-MM-dd HH:mm".
abstract final class Csv {
  static const bom = '﻿';

  static String encode(CsvOptions o) {
    final out = StringBuffer(bom)..write(_line([for (final h in o.header) _text(h)]));
    for (final row in o.rows) {
      out.write(_line([for (final cell in row) _cell(cell, o)]));
    }
    return out.toString();
  }

  static String _line(List<String> cells) => '${cells.join(',')}\r\n';

  static String _cell(Object? v, CsvOptions o) => switch (v) {
    null => '',
    final Money m => _money(m),
    final Grams g => _grams(g),
    final int i => '$i',
    final bool b => _text(b ? o.yes : o.no),
    final DateTime d => _date(d),
    final CodeCell c => _text(o.labels[c.code] ?? c.code),
    final String s => _text(s),
    _ => _text('$v'),
  };

  static String _money(Money m) {
    final abs = m.paise.abs();
    return '${m.paise < 0 ? '-' : ''}${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  static String _grams(Grams g) {
    final abs = g.milligrams.abs();
    return '${g.milligrams < 0 ? '-' : ''}${abs ~/ 1000}.${(abs % 1000).toString().padLeft(3, '0')}';
  }

  static String _date(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }

  static final _formulaStart = RegExp('^[=+\\-@\t\r]');
  static final _needsQuotes = RegExp('[",\r\n]|^ | \$');

  static String _text(String s) {
    final safe = _formulaStart.hasMatch(s) ? "'$s" : s;
    return _needsQuotes.hasMatch(safe) ? '"${safe.replaceAll('"', '""')}"' : safe;
  }
}
