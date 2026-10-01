import '../../../../core/money/money.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/dashboard.dart';

/// Maps the `dashboard_summary()` payload to the domain model.
DashboardSummary dashboardSummaryFromJson(Map<String, dynamic> json) => DashboardSummary(
  salesToday: Money.paise(json.requireInt('sales_today_paise')),
  paymentsToday: Money.paise(json.requireInt('payments_today_paise')),
  totalBaki: Money.paise(json.requireInt('total_baki_paise')),
  ordersToday: json.requireInt('orders_today'),
  pendingOrders: json.requireInt('pending_orders'),
  newMaalLast7Days: json.requireInt('new_maal_7d'),
);
