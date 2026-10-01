import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vepari/core/core.dart';

void main() {
  setUpAll(() async {
    for (final l in ['en', 'gu', 'hi']) {
      await initializeDateFormatting(l);
    }
  });

  test('grams from milligrams', () {
    expect(AppFormat.grams(42000), '42 g');
    expect(AppFormat.grams(4250), '4.25 g');
    expect(AppFormat.grams(1005), '1.005 g');
    expect(AppFormat.grams(1234000000), '12,34,000 g');
  });

  test('counts use Indian grouping', () => expect(AppFormat.count(150000), '1,50,000'));

  test('dates are locale-aware', () {
    final date = DateTime(2026, 10, 1, 16, 5);
    expect(AppFormat.shortDate(date, 'en'), '01 Oct');
    expect(AppFormat.fullDate(date, 'en'), '01 Oct 2026');
    expect(AppFormat.shortDate(date, 'gu'), isNot('01 Oct'));
    expect(AppFormat.shortDate(date, 'hi'), isNot('01 Oct'));
  });
}
