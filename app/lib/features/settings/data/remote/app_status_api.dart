import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/app_status.dart';

/// `app_status()` — callable before sign-in.
class AppStatusApi implements AppStatusRepository {
  const AppStatusApi(this._api);

  final ApiClient _api;

  @override
  Future<AppStatus?> fetch() async {
    try {
      return await _api.rpc(
        'app_status',
        decode: (json) {
          final j = asJsonObject(json);
          return AppStatus(minAppVersion: j.requireString('min_app_version'), maintenance: j['maintenance'] == true);
        },
        timeout: const Duration(seconds: 8),
      );
    } on AppFailure {
      return null; // offline or unreachable: never lock people out
    }
  }
}
