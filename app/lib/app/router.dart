import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../features/auth/auth.dart';
import '../features/catalogue/catalogue.dart';
import '../features/customers/customers.dart';
import '../features/dashboard/dashboard.dart';
import '../features/hisaab/hisaab.dart';
import '../features/orders/orders.dart';
import '../features/settings/settings.dart';
import 'not_found_screen.dart';
import 'shell.dart';

/// Route paths — the only place they are defined. Ids in paths are always
/// re-authorised by the server (RLS) when the screen loads.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const maal = '/maal';
  static const order = '/order';
  static const customer = '/customer';
  static const hisaab = '/hisaab';
  static const more = '/more';
  static const search = '/search';

  static String product(String id) => '$maal/product/$id';
  static String editProduct([String? id]) => id == null ? '$maal/edit' : '$maal/edit/$id';
  static const navoMaal = '$maal/navo';

  static String legalPath(LegalDocument doc) => '$more/legal/${doc.name}';
}

/// Session-aware redirect. Unknown identity → splash (no data), signed out →
/// login, signed in → app. Deep links are re-validated after login.
@visibleForTesting
String? redirectFor(SessionState session, String location) {
  final atAuthPage = location == AppRoutes.splash || location == AppRoutes.login;
  return switch (session) {
    SessionUnknown() => location == AppRoutes.splash ? null : AppRoutes.splash,
    SessionSignedOut() => location == AppRoutes.login ? null : AppRoutes.login,
    SessionSignedIn() => atAuthPage ? AppRoutes.home : null,
  };
}

LegalDocument? _legalDoc(GoRouterState state) =>
    LegalDocument.values.where((d) => d.name == state.pathParameters['doc']).firstOrNull;

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Rejects malformed ids in deep links before any request is made.
String? _requireUuid(GoRouterState state, String param, String fallback) =>
    _uuid.hasMatch(state.pathParameters[param] ?? '') ? null : fallback;

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  void onHomeNavigate(BuildContext context, HomeDestination destination) => switch (destination) {
    HomeDestination.orders => context.go(AppRoutes.order),
    HomeDestination.payment || HomeDestination.hisaab => context.go(AppRoutes.hisaab),
    HomeDestination.newMaal => context.push(AppRoutes.navoMaal),
  };

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(ref.read(sessionControllerProvider), state.matchedLocation),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) => HomeScreen(onNavigate: (d) => onHomeNavigate(context, d)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.maal,
                builder: (_, _) => const CatalogueScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.maal),
                    builder: (_, s) => ProductDetailScreen(productId: s.pathParameters['id']!),
                  ),
                  GoRoute(path: 'edit', builder: (_, _) => const ProductEditScreen()),
                  GoRoute(
                    path: 'edit/:id',
                    redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.maal),
                    builder: (_, s) => ProductEditScreen(productId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.order, builder: (_, _) => const OrdersScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.customer, builder: (_, _) => const CustomersScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.hisaab, builder: (_, _) => const HisaabScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, _) => MoreScreen(onOpenLegal: (doc) => context.push(AppRoutes.legalPath(doc))),
                routes: [
                  GoRoute(
                    path: 'legal/:doc',
                    // Unknown/malformed deep link → back to More, never a crash.
                    redirect: (_, state) => _legalDoc(state) == null ? AppRoutes.more : null,
                    builder: (_, state) => LegalScreen(document: _legalDoc(state)!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// go_router implementation of the [AppNavigator] port.
class GoRouterNavigator implements AppNavigator {
  GoRouterNavigator(this._router);

  final GoRouter _router;

  void _push(String location) => _router.push(location);

  @override
  void openSearch() => _push(AppRoutes.search);
  @override
  void openProduct(String productId) => _push(AppRoutes.product(productId));
  @override
  void editProduct([String? productId]) => _push(AppRoutes.editProduct(productId));
  @override
  void openNavoMaal() => _push(AppRoutes.navoMaal);

  @override
  void openCustomer(String customerId) => _push('${AppRoutes.customer}/$customerId');
  @override
  void editCustomer([String? customerId]) =>
      _push(customerId == null ? '${AppRoutes.customer}/new' : '${AppRoutes.customer}/$customerId/edit');
  @override
  void openCustomerRates(String customerId) => _push('${AppRoutes.customer}/$customerId/rates');

  @override
  void openCart({String? customerId}) =>
      _push(customerId == null ? '${AppRoutes.order}/cart' : '${AppRoutes.order}/cart?customer=$customerId');
  @override
  void openQuickOrder() => _push('${AppRoutes.order}/quick');
  @override
  void openOrder(String orderId) => _push('${AppRoutes.order}/$orderId');
  @override
  void openOrders({String? customerId, bool pendingOnly = false}) {
    final query = [if (customerId != null) 'customer=$customerId', if (pendingOnly) 'pending=1'].join('&');
    _push(query.isEmpty ? '${AppRoutes.order}/list' : '${AppRoutes.order}/list?$query');
  }

  @override
  void openHisaab(String customerId) => _push('${AppRoutes.hisaab}/$customerId');
  @override
  void openPayment(String customerId) => _push('${AppRoutes.hisaab}/$customerId/pay');

  @override
  void openBusinessProfile() => _push('${AppRoutes.more}/business');
  @override
  void openStaff() => _push('${AppRoutes.more}/staff');
  @override
  void openAudit() => _push('${AppRoutes.more}/audit');
  @override
  void openExport() => _push('${AppRoutes.more}/export');
  @override
  void openNotifications() => _push('${AppRoutes.more}/notifications');

  @override
  void back() {
    if (_router.canPop()) _router.pop();
  }
}
