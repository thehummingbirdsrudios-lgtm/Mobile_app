import '../../../core/core.dart';

/// Opens what a notification is about: from the inbox and from a tapped
/// push alike. The target screen loads it under RLS, so a stale or foreign
/// id shows that screen's not-found state and nothing else.
///
/// Returns false when the notification has nothing to open.
bool openNotificationTarget(AppNavigator nav, {required String kind, String? targetKind, String? targetId}) {
  final id = targetId;
  if (id == null) return false;
  switch (targetKind) {
    case 'product':
      nav.openProduct(id);
    case 'order':
      nav.openOrder(id);
    case 'customer':
      kind == 'payment_received' ? nav.openHisaab(id) : nav.openCustomer(id);
    case 'bill':
      nav.openBill(id);
    default:
      return false;
  }
  return true;
}
