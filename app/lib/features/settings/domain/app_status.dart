import 'package:meta/meta.dart';

/// Platform state the operator controls (server `app_status()`).
@immutable
class AppStatus {
  const AppStatus({required this.minAppVersion, required this.maintenance});

  final String minAppVersion;

  /// Business writes are paused; reads keep working.
  final bool maintenance;

  /// True when [current] is older than the minimum supported version.
  /// Unparseable versions never block (the server enforces security; this
  /// gate only keeps incompatible builds from misbehaving).
  bool blocks(String current) {
    final have = _parse(current);
    final need = _parse(minAppVersion);
    if (have == null || need == null) return false;
    for (var i = 0; i < 3; i++) {
      if (have[i] != need[i]) return have[i] < need[i];
    }
    return false;
  }

  static List<int>? _parse(String v) {
    final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(v.trim());
    return m == null ? null : [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
  }
}

/// Port. Returns null when the status cannot be read (the app then runs as
/// usual: fail open).
abstract interface class AppStatusRepository {
  Future<AppStatus?> fetch();
}
