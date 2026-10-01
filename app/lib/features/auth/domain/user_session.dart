import 'package:meta/meta.dart';

enum MemberRole { owner, staff }

/// Grantable staff permissions — mirrors the database enum `app_permission`.
/// The UI uses these only to hide actions; the server enforces them.
enum Permission {
  catalogueManage('catalogue.manage'),
  ratesManage('rates.manage'),
  customersManage('customers.manage'),
  ordersCreate('orders.create'),
  ordersManage('orders.manage'),
  paymentsRecord('payments.record'),
  hisaabView('hisaab.view'),
  hisaabAdjust('hisaab.adjust'),
  billsIssue('bills.issue'),
  reportsView('reports.view');

  const Permission(this.code);

  final String code;

  static Permission? fromCode(String code) {
    for (final p in values) {
      if (p.code == code) return p;
    }
    return null;
  }
}

/// The signed-in member, resolved by the server (`current_session()`).
@immutable
class UserSession {
  const UserSession({
    required this.userId,
    required this.tenantId,
    required this.username,
    required this.displayName,
    required this.businessName,
    required this.role,
    required this.permissions,
    this.defaultLocale,
  });

  final String userId;
  final String tenantId;
  final String username;
  final String displayName;
  final String businessName;
  final MemberRole role;
  final Set<Permission> permissions;
  final String? defaultLocale;

  bool get isOwner => role == MemberRole.owner;

  /// Owners hold every permission implicitly (same rule as the database).
  bool can(Permission permission) => isOwner || permissions.contains(permission);
}
