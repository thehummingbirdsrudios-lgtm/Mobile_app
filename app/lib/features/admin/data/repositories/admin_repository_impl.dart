import 'dart:async';
import 'dart:typed_data';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/format/phone.dart';
import '../../../../core/state/paged.dart';
import '../../../auth/auth.dart' show Permission;
import '../../domain/admin.dart';
import '../remote/admin_api.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AdminApi _remote;
  final DateTime Function() _clock;

  static String? _clean(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Future<BusinessProfile> profile() => _remote.profile();

  @override
  Future<void> saveProfile(BusinessProfileDraft draft, {required String tenantId}) async {
    if (draft.validate().isNotEmpty) throw const AppFailure(FailureKind.invalidInput);
    return _remote.updateProfile(tenantId, {
      'business_name': draft.businessName.trim(),
      'phone': PhoneNumbers.normalise(draft.phone),
      'whatsapp_phone': PhoneNumbers.normalise(draft.whatsappPhone),
      'address': _clean(draft.address),
      'gstin': BusinessProfileDraft.normaliseGstin(draft.gstin),
      'bill_footer': _clean(draft.billFooter),
      'watermark_enabled': draft.watermarkEnabled,
      'default_locale': BusinessProfileDraft.supportedLocales.contains(draft.defaultLocale)
          ? draft.defaultLocale
          : 'gu',
    });
  }

  @override
  Future<String> replaceLogo(Uint8List jpeg, {required String tenantId, required String sha256}) async {
    final previous = (await _remote.profile()).logoPath;
    // A new key per upload: bills and caches never show a stale logo, and
    // the bucket stays write-once for any given key.
    final path = '$tenantId/logo-${sha256.substring(0, 16)}-${_clock().millisecondsSinceEpoch}.jpg';
    await _remote.uploadLogo(path, jpeg);
    await _remote.updateProfile(tenantId, {'logo_path': path});
    if (previous != null && previous != path) unawaited(_removeQuietly(previous));
    return path;
  }

  @override
  Future<void> removeLogo({required String tenantId}) async {
    final previous = (await _remote.profile()).logoPath;
    await _remote.updateProfile(tenantId, {'logo_path': null});
    if (previous != null) unawaited(_removeQuietly(previous));
  }

  /// The profile no longer points at [path]; failing to delete it only
  /// leaves an unused private object behind (logged by ApiClient).
  Future<void> _removeQuietly(String path) async {
    try {
      await _remote.deleteLogo(path);
    } on AppFailure {
      // Already logged.
    }
  }

  @override
  Future<List<StaffMember>> members() => _remote.members();

  @override
  Future<void> setPermissions(String userId, Set<Permission> permissions) =>
      _remote.setPermissions(userId, permissions);

  @override
  Future<void> setActive(String userId, {required bool active}) => _remote.setActive(userId, active: active);

  @override
  Future<String> createStaff(NewStaff staff) async {
    if (staff.validate().isNotEmpty || NewStaff.passwordIssue(staff.password, username: staff.username) != null) {
      throw const AppFailure(FailureKind.invalidInput);
    }
    return _remote.createStaff(staff);
  }

  @override
  Future<void> resetPassword(String userId, String password) async {
    if (NewStaff.passwordIssue(password) != null) throw const AppFailure(FailureKind.invalidInput);
    return _remote.resetPassword(userId, password);
  }

  @override
  Future<PageResult<AuditEntry, int>> audit({int? before, int limit = 50}) =>
      _remote.audit(before: before, limit: limit);
}
