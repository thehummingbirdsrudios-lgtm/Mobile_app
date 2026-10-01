import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages the app ships with, in the order shown to users.
const supportedAppLocales = [Locale('gu'), Locale('hi'), Locale('en')];

/// Device-level preference storage port (not business data, not tenant-scoped).
abstract interface class PreferenceStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

/// Overridden at the composition root with the shared_preferences adapter.
final preferenceStoreProvider = Provider<PreferenceStore>(
  (ref) => throw UnimplementedError('preferenceStoreProvider must be overridden'),
);

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// The user's chosen language; null means "follow the device".
class LocaleController extends Notifier<Locale?> {
  static const _key = 'locale';

  @override
  Locale? build() {
    final code = ref.read(preferenceStoreProvider).getString(_key);
    return supportedAppLocales.where((l) => l.languageCode == code).firstOrNull;
  }

  Future<void> select(Locale locale) async {
    state = locale;
    await ref.read(preferenceStoreProvider).setString(_key, locale.languageCode);
  }
}

/// Picks the app locale: explicit choice → device language if supported → Gujarati.
Locale resolveAppLocale(Locale? chosen, List<Locale>? deviceLocales) {
  if (chosen != null) return chosen;
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final supported in supportedAppLocales) {
      if (supported.languageCode == device.languageCode) return supported;
    }
  }
  return supportedAppLocales.first;
}
