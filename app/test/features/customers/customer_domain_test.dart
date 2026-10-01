import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/features/customers/data/remote/customers_api.dart';
import 'package:vepari/features/customers/domain/customers.dart';

void main() {
  group('phone normalisation', () {
    test('Indian formats become 10 digits', () {
      expect(CustomerDraft.normalisePhone('+91 98250 12345'), '9825012345');
      expect(CustomerDraft.normalisePhone('919825012345'), '9825012345');
      expect(CustomerDraft.normalisePhone('098250-12345'), '9825012345');
      expect(CustomerDraft.normalisePhone(' 98250 12345 '), '9825012345');
    });

    test('international numbers keep their country code', () {
      expect(CustomerDraft.normalisePhone('+971 50 123 4567'), '+971501234567');
    });

    test('empty is null; junk fails validation', () {
      expect(CustomerDraft.normalisePhone('  '), isNull);
      expect(CustomerDraft.isValidPhone(CustomerDraft.normalisePhone('abc')), isFalse);
      expect(CustomerDraft.isValidPhone(CustomerDraft.normalisePhone('12345')), isFalse);
    });
  });

  test('draft validation mirrors the database checks', () {
    expect(const CustomerDraft(name: ' ').validate(), contains(CustomerIssue.nameRequired));
    expect(const CustomerDraft(name: 'Patel', phone: '123').validate(), {CustomerIssue.phoneInvalid});
    expect(const CustomerDraft(name: 'Patel', phone: '9825012345').validate(), isEmpty);
  });

  test('columns send only granted fields, normalised and trimmed', () {
    final cols = customerColumns(
      const CustomerDraft(name: ' Patel ', city: ' Rajkot ', phone: '+91 98250 12345', notes: ''),
    );
    expect(cols, {
      'name': 'Patel',
      'shop_name': null,
      'city': 'Rajkot',
      'phone': '9825012345',
      'whatsapp_phone': null,
      'notes': null,
    });
  });

  test('hidden Baki decodes as null, never as zero', () {
    final c = customerSummaryFromJson({
      'id': 'c1',
      'name': 'Patel',
      'shop_name': null,
      'city': 'Rajkot',
      'phone': null,
      'whatsapp_phone': null,
      'balance_paise': null,
      'last_activity_at': null,
      'sort_key': 'patel',
    });
    expect(c.baki, isNull);
    expect(c.place, 'Rajkot');
  });

  test('detail decodes counts and timestamps', () {
    final d = customerDetailFromJson({
      'id': 'c1',
      'name': 'Patel',
      'archived': false,
      'order_count': 12,
      'open_orders': 2,
      'special_rates': 1,
      'balance_paise': 4820000,
      'last_order_at': '2026-09-28T10:00:00+00:00',
    });
    expect(d.baki!.paise, 4820000);
    expect(d.lastOrderAt, DateTime.utc(2026, 9, 28, 10));
  });
}
