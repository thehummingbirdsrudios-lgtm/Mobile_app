import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/auth/data/remote/session_dto.dart';

void main() {
  group('Username', () {
    test('valid handles', () {
      for (final ok in ['rajesh', 'Rajesh ', 'owner_a', 'staff.1', 'r12']) {
        expect(Username.validate(ok), isNull, reason: ok);
      }
    });

    test('invalid handles', () {
      expect(Username.validate(''), UsernameIssue.empty);
      expect(Username.validate('   '), UsernameIssue.empty);
      for (final bad in ['ab', '_rajesh', 'raj esh', 'રાજેશ', 'a' * 33, 'raj@sh']) {
        expect(Username.validate(bad), UsernameIssue.invalid, reason: bad);
      }
    });

    test('login identifier is derived, lower-cased and trimmed', () {
      expect(Username.loginIdentifier(' Rajesh ', 'login.vepari.invalid'), 'rajesh@login.vepari.invalid');
    });
  });

  group('current_session mapping', () {
    final valid = <String, dynamic>{
      'user_id': 'u1',
      'tenant_id': 't1',
      'username': 'mahesh',
      'display_name': 'Maheshbhai',
      'business_name': 'Shree Jewels',
      'role': 'staff',
      'permissions': ['orders.create', 'hisaab.view', 'future.permission'],
      'default_locale': 'gu',
    };

    test('maps the contract and ignores unknown permissions (forward compatible)', () {
      final s = userSessionFromJson(valid);
      expect(s.role, MemberRole.staff);
      expect(s.permissions, {Permission.ordersCreate, Permission.hisaabView});
      expect(s.defaultLocale, 'gu');
    });

    test('missing or mistyped fields fail loudly with the field name', () {
      expect(() => userSessionFromJson({...valid}..remove('tenant_id')), throwsFormatException);
      expect(() => userSessionFromJson({...valid, 'role': 'admin'}), throwsFormatException);
      expect(() => userSessionFromJson({...valid, 'permissions': 'orders.create'}), throwsFormatException);
    });
  });
}
