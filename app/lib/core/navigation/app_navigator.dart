import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every destination a module may open, as a contract. Modules call this
/// port instead of importing each other's screens or knowing route strings,
/// which keeps feature modules free of import cycles. The app layer
/// implements it with go_router; tests use a recording fake.
abstract interface class AppNavigator {
  void openSearch();
  void openProduct(String productId);
  void editProduct([String? productId]);
  void openNavoMaal();

  void openCustomer(String customerId);
  void editCustomer([String? customerId]);
  void openCustomerRates(String customerId);

  void openCart({String? customerId});
  void openQuickOrder();
  void openOrder(String orderId);
  void openOrders({String? customerId, bool pendingOnly = false});

  void openHisaab(String customerId);
  void openPayment(String customerId);
  void openReceipt(String paymentId);
  void openBill(String billId);

  void openBusinessProfile();
  void openStaff();
  void openAudit();
  void openExport();
  void openNotifications();

  /// Pops the current route if possible.
  void back();
}

/// Overridden by the app layer (and in tests).
final appNavigatorProvider = Provider<AppNavigator>(
  (ref) => throw UnimplementedError('appNavigatorProvider must be overridden'),
);
