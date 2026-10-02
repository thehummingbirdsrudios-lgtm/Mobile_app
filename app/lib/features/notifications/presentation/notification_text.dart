import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notifications.dart';

String _s(Object? v) => v is String ? v : (v is num ? '$v' : '');

String _status(AppLocalizations l10n, Object? status) => switch (status) {
  'confirmed' => l10n.statusConfirmed,
  'processing' => l10n.statusProcessing,
  'ready' => l10n.statusReady,
  'completed' => l10n.statusCompleted,
  'cancelled' => l10n.statusCancelled,
  _ => _s(status),
};

/// The inbox line for a notification, in the user's language.
String notificationText(AppLocalizations l10n, AppNotification n) {
  final a = n.args;
  switch (n.kind) {
    case 'new_maal':
      return l10n.notifNewMaal([_s(a['design_no']), _s(a['name'])].where((s) => s.isNotEmpty).join(' · '));
    case 'order_update':
      return a['event'] == 'created'
          ? l10n.notifOrderCreated(_s(a['order_no']), _s(a['customer_name']))
          : l10n.notifOrderStatus(_s(a['order_no']), _status(l10n, a['status']));
    case 'payment_received':
      final paise = a['amount_paise'];
      return l10n.notifPayment(paise is int ? Money.paise(paise).format() : '', _s(a['customer_name']));
    default:
      return l10n.notifOther;
  }
}
