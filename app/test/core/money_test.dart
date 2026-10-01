import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

void main() {
  group('Money formatting (Indian grouping)', () {
    test('rupees without paise', () {
      expect(const Money.paise(0).format(), '₹0');
      expect(const Money.paise(62000).format(), '₹620');
      expect(const Money.paise(48200000).format(), '₹4,82,000');
      expect(const Money.paise(1234567800).format(), '₹1,23,45,678');
    });

    test('paise shown only when non-zero', () {
      expect(const Money.paise(12000050).format(), '₹1,20,000.50');
      expect(const Money.paise(5).format(), '₹0.05');
    });

    test('negative amounts (customer credit)', () {
      expect(const Money.paise(-50000).format(), '−₹500');
    });

    test('without symbol', () => expect(const Money.paise(150000).format(symbol: false), '1,500'));

    test('large values stay exact (no floating point)', () {
      expect(const Money.paise(Money.maxPaise).format(), '₹1,00,00,00,00,000');
    });
  });

  group('Money arithmetic', () {
    test('rate × qty and totals', () {
      const rate = Money.paise(62000);
      final total = Money.sum([rate.times(20), const Money.paise(32000).times(10)]);
      expect(total, const Money.paise(1560000));
    });

    test('baki after payment', () {
      expect(const Money.paise(8250000) - const Money.paise(1000000), const Money.paise(7250000));
    });

    test('equality and ordering', () {
      expect(const Money.paise(1), isNot(const Money.paise(2)));
      expect([const Money.paise(3), const Money.paise(1)]..sort(), [const Money.paise(1), const Money.paise(3)]);
    });
  });

  group('Money.tryParseRupees', () {
    test('valid inputs', () {
      expect(Money.tryParseRupees('620'), const Money.paise(62000));
      expect(Money.tryParseRupees('620.5'), const Money.paise(62050));
      expect(Money.tryParseRupees('1,20,000.75'), const Money.paise(12000075));
      expect(Money.tryParseRupees(' ₹10000 '), const Money.paise(1000000));
      expect(Money.tryParseRupees('0'), Money.zero);
    });

    test('invalid inputs are rejected, not guessed', () {
      for (final bad in ['', 'abc', '-5', '1.234', '1e5', '१००', '12 34', '99999999999999']) {
        expect(Money.tryParseRupees(bad), isNull, reason: bad);
      }
    });
  });
}
