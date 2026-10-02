import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/core.dart';
import 'core/network/api_client.dart' show SupabaseRpcTransport;
import 'core/network/storage_client.dart' show SupabaseObjectStorage;
import 'core/platform/firebase_push.dart';
import 'features/admin/admin.dart';
import 'features/admin/admin_adapters.dart';
import 'features/auth/auth.dart';
import 'features/auth/auth_adapters.dart';
import 'features/bills/bills.dart';
import 'features/bills/bills_adapters.dart';
import 'features/catalogue/catalogue.dart';
import 'features/catalogue/catalogue_adapters.dart';
import 'features/customers/customers.dart';
import 'features/customers/customers_adapters.dart';
import 'features/dashboard/dashboard.dart';
import 'features/dashboard/dashboard_adapters.dart';
import 'features/export/export.dart';
import 'features/export/export_adapters.dart';
import 'features/hisaab/hisaab.dart';
import 'features/hisaab/hisaab_adapters.dart';
import 'features/notifications/notifications.dart';
import 'features/notifications/notifications_adapters.dart';
import 'features/orders/orders.dart';
import 'features/orders/orders_adapters.dart';
import 'features/remarks/remarks.dart';
import 'features/remarks/remarks_adapters.dart';
import 'features/search/search.dart';
import 'features/search/search_adapters.dart';
import 'features/settings/settings.dart';
import 'features/settings/settings_adapters.dart';
import 'features/sharing/sharing.dart';
import 'features/sharing/sharing_adapters.dart';
import 'firebase_options.dart';

/// Composition root: the only place concrete adapters (Supabase) are wired
/// to module ports. Everything else depends on interfaces.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final logger = AppLogger.forBuild();
  logger.info('app.start', {'env': config.environment, 'version': config.appVersion});
  final preferences = await SharedPreferencesStore.create();
  // Files left by a share that was interrupted (bills, receipts, exports).
  unawaited(const SystemFileSharer().sweep());

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
      hisaabRepositoryProvider.overrideWithValue(HisaabRepositoryImpl(HisaabApi(api))),
      billsRepositoryProvider.overrideWithValue(BillsRepositoryImpl(BillsApi(api))),
      sharingRepositoryProvider.overrideWithValue(SharingRepositoryImpl(SharingApi(api, storage))),
      remarksRepositoryProvider.overrideWithValue(RemarksRepositoryImpl(RemarksApi(client, api, storage))),
      adminRepositoryProvider.overrideWithValue(AdminRepositoryImpl(AdminApi(client, api, storage))),
      notificationsRepositoryProvider.overrideWithValue(NotificationsRepositoryImpl(NotificationsApi(api))),
      exportRepositoryProvider.overrideWithValue(ExportRepositoryImpl(ExportApi(api))),
      appStatusRepositoryProvider.overrideWithValue(AppStatusApi(api)),
      authRepositoryProvider.overrideWithValue(
        AuthRepositoryImpl(AuthApi(client.auth, api), loginDomain: config.loginDomain),
      ),
      dashboardRepositoryProvider.overrideWithValue(DashboardRepositoryImpl(DashboardApi(api))),
      searchRepositoryProvider.overrideWithValue(SearchRepositoryImpl(SearchApi(api), RecentSearchStore(preferences))),
    ]);
    final push = await _firebasePush(logger);
    if (push != null) overrides.add(pushTokenSourceProvider.overrideWithValue(push));
  } else {
    overrides.add(authRepositoryProvider.overrideWithValue(const UnconfiguredAuthRepository()));
  }

  runApp(ProviderScope(overrides: overrides, child: const VepariApp()));
}

/// FCM on Android when this build carries Firebase options; otherwise the
/// app runs without push and notifications stay in the in-app inbox.
Future<PushTokenSource?> _firebasePush(AppLogger logger) async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options == null) return null;
  try {
    await Firebase.initializeApp(options: options);
    return FirebasePushTokens(FirebaseMessaging.instance);
  } on Object catch (e) {
    logger.warning('push.init_failed', {'error': e.runtimeType.toString()});
    return null;
  }
}
