import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/core.dart';
import 'core/network/api_client.dart' show SupabaseRpcTransport;
import 'core/network/storage_client.dart' show SupabaseObjectStorage;
import 'features/auth/auth.dart';
import 'features/auth/auth_adapters.dart';
import 'features/catalogue/catalogue.dart';
import 'features/catalogue/catalogue_adapters.dart';
import 'features/customers/customers.dart';
import 'features/customers/customers_adapters.dart';
import 'features/dashboard/dashboard.dart';
import 'features/dashboard/dashboard_adapters.dart';
import 'features/orders/orders.dart';
import 'features/orders/orders_adapters.dart';
import 'features/search/search.dart';
import 'features/search/search_adapters.dart';
import 'features/settings/settings.dart';
import 'features/settings/settings_adapters.dart';

/// Composition root: the only place concrete adapters (Supabase) are wired
/// to module ports. Everything else depends on interfaces.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final logger = AppLogger.forBuild();
  logger.info('app.start', {'env': config.environment, 'version': config.appVersion});
  final preferences = await SharedPreferencesStore.create();

  final overrides = [
    ...appLayerOverrides,
    appConfigProvider.overrideWithValue(config),
    preferenceStoreProvider.overrideWithValue(preferences),
    cartStoreProvider.overrideWithValue(PreferencesCartStore(preferences)),
  ];

  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
      debug: false,
    );
    final client = Supabase.instance.client;
    final api = ApiClient(transport: SupabaseRpcTransport(client), logger: logger);
    final storage = SupabaseObjectStorage(client, api);
    overrides.addAll([
      storageClientProvider.overrideWithValue(storage),
      catalogueRepositoryProvider.overrideWithValue(CatalogueRepositoryImpl(CatalogueApi(client, api, storage))),
      customerRepositoryProvider.overrideWithValue(CustomerRepositoryImpl(CustomersApi(client, api))),
      ordersRepositoryProvider.overrideWithValue(OrdersRepositoryImpl(OrdersApi(api))),
      authRepositoryProvider.overrideWithValue(
        AuthRepositoryImpl(AuthApi(client.auth, api), loginDomain: config.loginDomain),
      ),
      dashboardRepositoryProvider.overrideWithValue(DashboardRepositoryImpl(DashboardApi(api))),
      searchRepositoryProvider.overrideWithValue(SearchRepositoryImpl(SearchApi(api), RecentSearchStore(preferences))),
    ]);
  } else {
    overrides.add(authRepositoryProvider.overrideWithValue(const UnconfiguredAuthRepository()));
  }

  runApp(ProviderScope(overrides: overrides, child: const VepariApp()));
}
