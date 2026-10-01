import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth.dart';
import '../features/catalogue/catalogue.dart';
import '../features/customers/customers.dart';
import '../features/dashboard/dashboard.dart';
import '../features/hisaab/hisaab.dart';
import '../features/orders/orders.dart';
import '../features/settings/settings.dart';
import 'shell.dart';

/// Route paths — the only place they are defined.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const maal = '/maal';
  static const order = '/order';
  static const customer = '/customer';
  static const hisaab = '/hisaab';
  static const more = '/more';
  static const legal = 'legal/:doc';

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

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  void onHomeNavigate(BuildContext context, HomeDestination destination) => switch (destination) {
    HomeDestination.orders => context.go(AppRoutes.order),
    HomeDestination.payment || HomeDestination.hisaab => context.go(AppRoutes.hisaab),
    HomeDestination.newMaal => context.go(AppRoutes.maal),
  };

  StatefulShellBranch branch(String path, Widget screen, {List<RouteBase> routes = const []}) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, _) => screen, routes: routes)],
  );

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(ref.read(sessionControllerProvider), state.matchedLocation),
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
          branch(AppRoutes.maal, const CatalogueScreen()),
          branch(AppRoutes.order, const OrdersScreen()),
          branch(AppRoutes.customer, const CustomersScreen()),
          branch(AppRoutes.hisaab, const HisaabScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, _) => MoreScreen(onOpenLegal: (doc) => context.push(AppRoutes.legalPath(doc))),
                routes: [
                  GoRoute(
                    path: AppRoutes.legal,
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
