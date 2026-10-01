import '../../domain/dashboard.dart';
import '../remote/dashboard_api.dart';

/// Today's numbers are always fetched fresh (they change with every order
/// and payment); a short-lived cache can be added here without touching UI.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remote);

  final DashboardApi _remote;

  @override
  Future<DashboardSummary> fetchSummary() => _remote.fetchSummary();
}
