import 'package:shared_preferences/shared_preferences.dart';

import '../../application/locale_controller.dart';

/// [PreferenceStore] backed by shared_preferences (non-sensitive device prefs only).
class SharedPreferencesStore implements PreferenceStore {
  SharedPreferencesStore(this._prefs);

  static Future<SharedPreferencesStore> create() async => SharedPreferencesStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {'locale'}),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
}
