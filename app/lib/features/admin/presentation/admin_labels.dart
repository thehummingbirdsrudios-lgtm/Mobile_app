import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../domain/admin.dart';

/// Plain-language name of a permission, in the user's language.
String permissionLabel(AppLocalizations l10n, Permission p) => switch (p) {
  Permission.catalogueManage => l10n.permCatalogueManage,
  Permission.ratesManage => l10n.permRatesManage,
  Permission.customersManage => l10n.permCustomersManage,
  Permission.ordersCreate => l10n.permOrdersCreate,
  Permission.ordersManage => l10n.permOrdersManage,
  Permission.paymentsRecord => l10n.permPaymentsRecord,
  Permission.hisaabView => l10n.permHisaabView,
  Permission.hisaabAdjust => l10n.permHisaabAdjust,
  Permission.billsIssue => l10n.permBillsIssue,
  Permission.reportsView => l10n.permReportsView,
};

String _thing(AppLocalizations l10n, String entity) => switch (entity) {
  'products' => l10n.auditEntityProduct,
  'product_private' => l10n.auditEntityCost,
  'customers' => l10n.auditEntityCustomer,
  'customer_product_rates' => l10n.auditEntityCustomerRate,
  'business_profiles' => l10n.adminBusinessProfile,
  'tenant_members' || 'member_permissions' => l10n.auditEntityMember,
  _ => l10n.auditEntityRecord,
};

Object? _from(AuditEntry e, String field) => (e.data[field] as Map?)?['from'];
Object? _to(AuditEntry e, String field) => (e.data[field] as Map?)?['to'];

String _permission(AppLocalizations l10n, Object? code) {
  final p = code is String ? Permission.fromCode(code) : null;
  return p == null ? '$code' : permissionLabel(l10n, p);
}

/// One line saying what happened, e.g. "Rate changed ₹600 → ₹620".
String auditTitle(AppLocalizations l10n, AuditEntry e) {
  switch (e.action) {
    case 'order.created':
      return l10n.auditOrderCreated;
    case 'order.status':
      return l10n.auditOrderStatus;
    case 'order.cancelled':
      return l10n.auditOrderCancelled;
    case 'payment.recorded':
      return l10n.auditPaymentRecorded;
    case 'bill.issued':
      return l10n.auditBillIssued;
    case 'ledger.opening':
      return l10n.auditLedgerOpening;
    case 'staff.created':
      return l10n.auditStaffCreated;
    case 'staff.password_reset':
      return l10n.auditStaffPasswordReset;
  }
  if (e.action.startsWith('ledger.')) return l10n.auditLedgerAdjustment;

  if (e.entity == 'member_permissions') {
    if (e.action == 'insert') return l10n.auditPermissionGranted(_permission(l10n, _to(e, 'permission')));
    if (e.action == 'delete') return l10n.auditPermissionRevoked(_permission(l10n, _from(e, 'permission')));
  }
  if (e.entity == 'tenant_members' && e.action == 'update' && e.data.containsKey('is_active')) {
    return _to(e, 'is_active') == true ? l10n.staffAccessRestored : l10n.staffAccessStopped;
  }
  final (from, to) = (_from(e, 'rate_paise'), _to(e, 'rate_paise'));
  if (e.action == 'update' && from is int && to is int) {
    return l10n.auditRateChanged(Money.paise(from).format(), Money.paise(to).format());
  }

  final thing = _thing(l10n, e.entity);
  return switch (e.action) {
    'insert' => l10n.auditAdded(thing),
    'delete' => l10n.auditRemoved(thing),
    _ => l10n.auditChanged(thing),
  };
}

/// Shows [child] only to the signed-in owner. Everyone else gets an honest
/// "owner only" screen (the server refuses them anyway).
class OwnerOnly extends ConsumerWidget {
  const OwnerOnly({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(currentSessionProvider.select((s) => s?.isOwner ?? false));
    if (isOwner) return child;
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(icon: Icons.lock_outline_rounded, title: AppLocalizations.of(context).adminOwnerOnly),
    );
  }
}
