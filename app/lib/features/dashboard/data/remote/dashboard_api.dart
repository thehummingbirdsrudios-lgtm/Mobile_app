import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/dashboard.dart';
import 'dashboard_dto.dart';

/// Remote data source for the `dashboard_summary` RPC.
class DashboardApi {
  const DashboardApi(this._api);

  final ApiClient _api;

  Future<DashboardSummary> fetchSummary() =>
      _api.rpc('dashboard_summary', decode: (json) => dashboardSummaryFromJson(asJsonObject(json)));
}
