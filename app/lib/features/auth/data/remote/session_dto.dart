import '../../../../core/network/json_reader.dart';
import '../../domain/user_session.dart';

/// Maps the `current_session()` payload (API contract, docs/architecture/api.md)
/// to the domain model. Unknown permission codes from a newer server are
/// ignored rather than crashing an older app (forward compatibility).
UserSession userSessionFromJson(Map<String, dynamic> json) => UserSession(
  userId: json.requireString('user_id'),
  tenantId: json.requireString('tenant_id'),
  username: json.requireString('username'),
  displayName: json.requireString('display_name'),
  businessName: json.requireString('business_name'),
  role: switch (json.requireString('role')) {
    'owner' => MemberRole.owner,
    'staff' => MemberRole.staff,
    final other => throw FormatException('unknown role', other),
  },
  permissions: {for (final code in json.stringList('permissions')) ?Permission.fromCode(code)},
  defaultLocale: json.optionalString('default_locale'),
);
