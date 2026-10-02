import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/storage_client.dart';
import '../../../../core/state/paged.dart';
import '../../../auth/auth.dart' show MemberRole, Permission;
import '../../domain/admin.dart';

/// Remote data source for owner administration:
/// - business profile: RLS (owner-only UPDATE) + column grants,
/// - members and audit: owner RPCs (`member_list`, `set_member_*`, `audit_page`),
/// - logins: the `staff-admin` Edge Function (needs the Auth admin API).
class AdminApi {
  const AdminApi(this._client, this._api, this._storage);

  final SupabaseClient _client;
  final ApiClient _api;
  final StorageClient _storage;

  static const _profileColumns =
      'business_name, phone, whatsapp_phone, address, gstin, bill_footer, logo_path, watermark_enabled, default_locale';

  Future<BusinessProfile> profile() => _api.run(
    'business_profiles.select',
    () async => businessProfileFromJson(await _client.from('business_profiles').select(_profileColumns).single()),
  );

  Future<void> updateProfile(String tenantId, Map<String, Object?> columns) =>
      _api.run('business_profiles.update', () async {
        final rows = await _client
            .from('business_profiles')
            .update(columns)
            .eq('tenant_id', tenantId)
            .select('tenant_id');
        // RLS hides the row from non-owners: zero rows means "not allowed".
        if (rows.isEmpty) throw const AppFailure(FailureKind.permissionDenied);
      });

  Future<void> uploadLogo(String path, Uint8List jpeg) =>
      _storage.upload(Buckets.branding, path, jpeg, contentType: 'image/jpeg');

  Future<void> deleteLogo(String path) =>
      _api.run('storage.remove', () => _client.storage.from(Buckets.branding).remove([path]));

  Future<List<StaffMember>> members() => _api.rpc(
    'member_list',
    decode: (json) => [for (final r in (json as List? ?? const [])) staffMemberFromJson(asJsonObject(r))],
  );

  Future<void> setPermissions(String userId, Set<Permission> permissions) => _api.rpc(
    'set_member_permissions',
    params: {
      'p_user_id': userId,
      'p_permissions': [for (final p in permissions) p.code],
    },
    decode: (_) {},
  );

  Future<void> setActive(String userId, {required bool active}) =>
      _api.rpc('set_member_active', params: {'p_user_id': userId, 'p_active': active}, decode: (_) {});

  Future<PageResult<AuditEntry, int>> audit({int? before, required int limit}) async {
    final rows = await _api.rpc(
      'audit_page',
      params: {'p_before_id': before, 'p_limit': limit},
      decode: (json) => [for (final r in (json as List? ?? const [])) auditEntryFromJson(asJsonObject(r))],
    );
    return PageResult(rows, next: rows.length < limit ? null : rows.last.id);
  }

  Future<String> createStaff(NewStaff staff) => _api.run('fn.staff-admin.create', () async {
    final response = await _client.functions.invoke(
      'staff-admin',
      body: {
        'action': 'create_staff',
        'username': staff.username.trim().toLowerCase(),
        'display_name': staff.displayName.trim(),
        'password': staff.password,
        'permissions': [for (final p in staff.permissions) p.code],
      },
    );
    return asJsonObject(response.data).requireString('user_id');
  }, timeout: const Duration(seconds: 30));

  Future<void> resetPassword(String userId, String password) => _api.run('fn.staff-admin.reset', () async {
    await _client.functions.invoke(
      'staff-admin',
      body: {'action': 'reset_password', 'user_id': userId, 'password': password},
    );
  }, timeout: const Duration(seconds: 30));
}

BusinessProfile businessProfileFromJson(Map<String, dynamic> j) => BusinessProfile(
  businessName: j.requireString('business_name'),
  phone: j.optionalString('phone'),
  whatsappPhone: j.optionalString('whatsapp_phone'),
  address: j.optionalString('address'),
  gstin: j.optionalString('gstin'),
  billFooter: j.optionalString('bill_footer'),
  logoPath: j.optionalString('logo_path'),
  watermarkEnabled: j['watermark_enabled'] != false,
  defaultLocale: j.optionalString('default_locale') ?? 'gu',
);

StaffMember staffMemberFromJson(Map<String, dynamic> j) => StaffMember(
  userId: j.requireString('user_id'),
  username: j.requireString('username'),
  displayName: j.requireString('display_name'),
  role: switch (j.requireString('role')) {
    'owner' => MemberRole.owner,
    'staff' => MemberRole.staff,
    final other => throw FormatException('unknown role', other),
  },
  isActive: j['is_active'] == true,
  // Unknown future permissions are ignored, never guessed.
  permissions: {
    for (final code in (j['permissions'] as List? ?? const []))
      if (code is String) ?Permission.fromCode(code),
  },
);

AuditEntry auditEntryFromJson(Map<String, dynamic> j) => AuditEntry(
  id: j.requireInt('id'),
  action: j.requireString('action'),
  entity: j.requireString('entity'),
  entityId: j.optionalString('entity_id'),
  data: j['data'] is Map ? Map<String, Object?>.from(j['data'] as Map) : const {},
  actorName: j.optionalString('actor_name'),
  createdAt: j.requireDateTime('created_at'),
  subject: j.optionalString('subject'),
);
