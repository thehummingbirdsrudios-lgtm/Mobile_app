import 'package:meta/meta.dart';

import '../../../core/money/money.dart';

/// "Aaje shu che?" — today's numbers, computed by the server in the tenant's timezone.
@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.salesToday,
    required this.paymentsToday,
    required this.totalBaki,
    required this.ordersToday,
    required this.pendingOrders,
    required this.newMaalLast7Days,
  });

  final Money salesToday;
  final Money paymentsToday;
  final Money totalBaki;
  final int ordersToday;
  final int pendingOrders;
  final int newMaalLast7Days;
}

abstract interface class DashboardRepository {
  /// Throws `AppFailure`.
  Future<DashboardSummary> fetchSummary();
}
