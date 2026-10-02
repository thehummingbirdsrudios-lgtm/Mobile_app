/// Settings (More) module public API.
library;

export 'application/app_status_provider.dart' show appStatusProvider, appStatusRepositoryProvider;
export 'application/locale_controller.dart'
    show PreferenceStore, localeControllerProvider, preferenceStoreProvider, resolveAppLocale, supportedAppLocales;
export 'domain/app_status.dart' show AppStatus, AppStatusRepository;
export 'presentation/app_gate.dart' show AppGate;
export 'presentation/legal_screen.dart' show LegalDocument, LegalScreen;
export 'presentation/more_screen.dart' show MoreScreen;
