import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/admin/admin.dart';
import 'package:vepari/features/admin/admin_adapters.dart';
import 'package:vepari/features/admin/data/remote/admin_api.dart' show auditEntryFromJson, staffMemberFromJson;
import 'package:vepari/features/admin/domain/admin.dart' show NewStaffIssue, ProfileIssue;
import 'package:vepari/features/admin/presentation/admin_labels.dart' show auditTitle;
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/l10n/app_localizations_en.dart';

/// Records what the repository sends; never touches a network.
class _RecordingApi implements AdminApi {
  BusinessProfile profileValue = const BusinessProfile(businessName: 'Shree Jewels', logoPath: 't-a/logo-old.jpg');
  final updates = <(String, Map<String, Object?>)>[];
  final uploads = <String>[];
  final deletes = <String>[];
  final created = <NewStaff>[];

  @override
  Future<BusinessProfile> profile() async => profileValue;

  @override
  Future<void> updateProfile(String tenantId, Map<String, Object?> columns) async => updates.add((tenantId, columns));

  @override
  Future<void> uploadLogo(String path, Uint8List jpeg) async => uploads.add(path);

  @override
  Future<void> deleteLogo(String path) async => deletes.add(path);

  @override
  Future<String> createStaff(NewStaff staff) async {
    created.add(staff);
    return 'new-id';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final l10n = AppLocalizationsEn();

  group('business profile rules (mirror the database CHECKs)', () {
    test('GSTIN is normalised and checked', () {
      expect(BusinessProfileDraft.normaliseGstin(' 24abcde 1234f1z5 '), '24ABCDE1234F1Z5');
      expect(BusinessProfileDraft.normaliseGstin('  '), isNull);
      expect(BusinessProfileDraft.isValidGstin('24ABCDE1234F1Z5'), isTrue);
      expect(BusinessProfileDraft.isValidGstin(''), isTrue);
      expect(BusinessProfileDraft.isValidGstin('24ABC'), isFalse);
      expect(BusinessProfileDraft.isValidGstin('24ABCDE1234F1Z!'), isFalse);
    });

    test('validate lists every problem', () {
      final draft = BusinessProfileDraft(
        businessName: ' ',
        phone: '12',
        whatsappPhone: 'abc',
        gstin: 'x',
        address: 'a' * 401,
        billFooter: 'f' * 401,
      );
      expect(draft.validate(), {
        ProfileIssue.nameRequired,
        ProfileIssue.phoneInvalid,
        ProfileIssue.whatsappInvalid,
        ProfileIssue.gstinInvalid,
        ProfileIssue.addressTooLong,
        ProfileIssue.footerTooLong,
      });
      expect(const BusinessProfileDraft(businessName: 'Shree', phone: '+91 98250 12345').validate(), isEmpty);
    });
  });

  group('staff rules', () {
    test('passwords are 8–72 UTF-8 bytes and not the username', () {
      expect(NewStaff.passwordIssue('short'), PasswordIssue.tooShort);
      expect(NewStaff.passwordIssue('        '), PasswordIssue.tooShort);
      expect(NewStaff.passwordIssue('a' * 72), isNull);
      expect(NewStaff.passwordIssue('a' * 73), PasswordIssue.tooLong);
      // 25 Gujarati letters are 75 bytes: bcrypt would silently cut them.
      expect(NewStaff.passwordIssue('ઘ' * 25), PasswordIssue.tooLong);
      expect(NewStaff.passwordIssue('KiranBhai', username: ' kiranbhai '), PasswordIssue.sameAsUsername);
      expect(NewStaff.passwordIssue('Moti-Haar-2026', username: 'kiran'), isNull);
    });

    test('username and name follow the login rules', () {
      const ok = NewStaff(username: 'Kiran.B', displayName: 'Kiran', password: 'x');
      expect(ok.validate(), isEmpty);
      expect(const NewStaff(username: '', displayName: 'K', password: 'x').validate(), {NewStaffIssue.usernameEmpty});
      expect(const NewStaff(username: 'a b', displayName: ' ', password: 'x').validate(), {
        NewStaffIssue.usernameInvalid,
        NewStaffIssue.nameRequired,
      });
    });
  });

  group('parsing', () {
    test('members: unknown permissions are ignored, never guessed', () {
      final m = staffMemberFromJson({
        'user_id': 'u1',
        'username': 'kiran',
        'display_name': 'Kiranbhai',
        'role': 'staff',
        'is_active': true,
        'permissions': ['orders.create', 'future.permission'],
      });
      expect(m.permissions, {Permission.ordersCreate});
      expect(
        () => staffMemberFromJson({
          ...{'user_id': 'u', 'username': 'x', 'display_name': 'y'},
          'role': 'admin',
        }),
        throwsFormatException,
      );
    });

    test('audit rows', () {
      final e = auditEntryFromJson({
        'id': 7,
        'action': 'update',
        'entity': 'products',
        'entity_id': 'p1',
        'data': {
          'rate_paise': {'from': 60000, 'to': 62000},
        },
        'actor_name': null,
        'created_at': '2026-10-01T10:00:00Z',
        'subject': '1024 · Kundan Set',
      });
      expect(e.id, 7);
      expect(e.actorName, isNull);
      expect(e.subject, '1024 · Kundan Set');
      expect(e.changedFields, ['rate_paise']);
    });
  });

  group('audit titles', () {
    AuditEntry entry(String action, String entity, [Map<String, Object?> data = const {}]) =>
        AuditEntry(id: 1, action: action, entity: entity, data: data, createdAt: DateTime.utc(2026));

    test('business actions', () {
      expect(auditTitle(l10n, entry('order.created', 'orders')), 'Order taken');
      expect(auditTitle(l10n, entry('order.cancelled', 'orders')), 'Order cancelled');
      expect(auditTitle(l10n, entry('payment.recorded', 'payments')), 'Payment recorded');
      expect(auditTitle(l10n, entry('bill.issued', 'bills')), 'Bill made');
      expect(auditTitle(l10n, entry('ledger.opening', 'ledger_entries')), 'Opening Baki set');
      expect(auditTitle(l10n, entry('ledger.reversal', 'ledger_entries')), 'Hisaab corrected');
      expect(auditTitle(l10n, entry('staff.created', 'tenant_members')), 'Staff login created');
      expect(auditTitle(l10n, entry('staff.password_reset', 'tenant_members')), 'Staff password changed');
    });

    test('row changes say what changed', () {
      expect(
        auditTitle(
          l10n,
          entry('insert', 'member_permissions', {
            'permission': {'from': null, 'to': 'bills.issue'},
          }),
        ),
        'Permission given: Make bills',
      );
      expect(
        auditTitle(
          l10n,
          entry('update', 'tenant_members', {
            'is_active': {'from': true, 'to': false},
          }),
        ),
        'Access stopped',
      );
      expect(
        auditTitle(
          l10n,
          entry('update', 'customer_product_rates', {
            'rate_paise': {'from': 50000, 'to': 48000},
          }),
        ),
        'Rate changed from ₹500 to ₹480',
      );
      expect(auditTitle(l10n, entry('update', 'product_private', {'cost_paise': 'changed'})), 'Cost details changed');
      expect(auditTitle(l10n, entry('insert', 'customers')), 'Customer added');
      expect(auditTitle(l10n, entry('update', 'business_profiles')), 'Business details changed');
      expect(auditTitle(l10n, entry('delete', 'something_new')), 'Record removed');
    });
  });

  group('AdminRepositoryImpl', () {
    test('saves normalised profile values for the given tenant', () async {
      final api = _RecordingApi();
      await AdminRepositoryImpl(api).saveProfile(
        const BusinessProfileDraft(
          businessName: '  Shree Jewels ',
          phone: '+91 98250 12345',
          address: '  ',
          gstin: '24abcde1234f1z5',
          billFooter: ' Thank you ',
          watermarkEnabled: false,
          defaultLocale: 'xx',
        ),
        tenantId: 't-a',
      );
      final (tenant, columns) = api.updates.single;
      expect(tenant, 't-a');
      expect(columns, {
        'business_name': 'Shree Jewels',
        'phone': '9825012345',
        'whatsapp_phone': null,
        'address': null,
        'gstin': '24ABCDE1234F1Z5',
        'bill_footer': 'Thank you',
        'watermark_enabled': false,
        'default_locale': 'gu',
      });
    });

    test('an invalid profile never reaches the server', () async {
      final api = _RecordingApi();
      await expectLater(
        AdminRepositoryImpl(api).saveProfile(const BusinessProfileDraft(businessName: ''), tenantId: 't-a'),
        throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.invalidInput)),
      );
      expect(api.updates, isEmpty);
    });

    test('a new logo gets a fresh key in the tenant folder; the old one is removed', () async {
      final api = _RecordingApi();
      final repo = AdminRepositoryImpl(api, clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000));
      final path = await repo.replaceLogo(Uint8List(4), tenantId: 't-a', sha256: 'ab' * 32);
      expect(path, 't-a/logo-abababababababab-1700000000000.jpg');
      expect(api.uploads, [path]);
      expect(api.updates.single.$2, {'logo_path': path});
      await Future<void>.delayed(Duration.zero);
      expect(api.deletes, ['t-a/logo-old.jpg']);
    });

    test('invalid staff and passwords are refused locally', () async {
      final api = _RecordingApi();
      final repo = AdminRepositoryImpl(api);
      await expectLater(
        repo.createStaff(const NewStaff(username: 'kiranbhai', displayName: 'Kiran', password: 'KiranBhai')),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(repo.resetPassword('u1', 'short'), throwsA(isA<AppFailure>()));
      expect(api.created, isEmpty);
      await repo.createStaff(const NewStaff(username: 'kiran', displayName: 'Kiran', password: 'Moti-Haar-2026'));
      expect(api.created, hasLength(1));
    });
  });
}
