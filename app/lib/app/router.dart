import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../features/auth/auth.dart';
import '../features/bills/bills.dart';
import '../features/catalogue/catalogue.dart';
import '../features/customers/customers.dart';
import '../features/dashboard/dashboard.dart';
import '../features/hisaab/hisaab.dart';
import '../features/orders/orders.dart';
import '../features/search/search.dart';
import '../features/settings/settings.dart';
import 'not_found_screen.dart';
import 'shell.dart';

/// Route paths — the only place they are defined. Ids in paths are always
/// re-authorised by the server (RLS) when the screen loads.
abstract final class AppRoutes {
  // Tabs (inside the shell).
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const maal = '/maal';
  static const order = '/order';
  static const customer = '/customer';
  static const hisaab = '/hisaab';
  static const more = '/more';

  // Full-screen routes above the tabs. Detail and editor screens live here
  // so they can be opened from any tab, from search or from a deep link.
  static const search = '/search';
  static const navoMaal = '/navo-maal';
  static const newProduct = '/product/new';
  static String product(String id) => '/product/$id';
  static String editProduct([String? id]) => id == null ? newProduct : '/product/$id/edit';

  static const newCustomer = '/customers/new';
  static String customerDetail(String id) => '/customers/$id';
  static String editCustomer([String? id]) => id == null ? newCustomer : '/customers/$id/edit';
  static String customerRates(String id) => '/customers/$id/rates';

  static const quickOrder = '/quick-order';
  static String cart({String? customerId}) => customerId == null ? '/cart' : '/cart?customer=$customerId';
  static String orderDetail(String id) => '/orders/$id';
  static String orders({String? customerId, bool pendingOnly = false}) {
    final query = [if (customerId != null) 'customer=$customerId', if (pendingOnly) 'pending=1'].join('&');
    return query.isEmpty ? '/orders' : '/orders?$query';
  }

  static String ledger(String customerId) => '/ledger/$customerId';
  static String payment(String customerId) => '/ledger/$customerId/pay';
  static String receipt(String paymentId) => '/receipts/$paymentId';
  static String bill(String billId) => '/bills/$billId';

  static const businessProfile = '/settings/business';
  static const staff = '/settings/staff';
  static const audit = '/settings/audit';
  static const export = '/settings/export';
  static const notifications = '/settings/notifications';

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

String? _uuidOrNull(String? value) => value != null && _uuid.hasMatch(value) ? value : null;

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
      GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(path: AppRoutes.navoMaal, builder: (_, _) => const NavoMaalScreen()),
      GoRoute(path: AppRoutes.newCustomer, builder: (_, _) => const CustomerEditScreen()),
      GoRoute(
        path: '/cart',
        builder: (_, s) => CartScreen(customerId: _uuidOrNull(s.uri.queryParameters['customer'])),
      ),
      GoRoute(
        path: '/ledger/:id',
        redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.hisaab),
        builder: (_, s) => LedgerScreen(customerId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'pay',
            builder: (_, s) => PaymentScreen(customerId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/bills/:id',
        redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.order),
        builder: (_, s) => BillScreen(billId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/receipts/:id',
        redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.hisaab),
        builder: (_, s) => ReceiptScreen(paymentId: s.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.quickOrder, builder: (_, _) => const CartScreen(quickEntry: true)),
      GoRoute(
        path: '/orders',
        builder: (_, s) => CustomerOrdersScreen(
          query: OrderQuery(
            customerId: _uuidOrNull(s.uri.queryParameters['customer']),
            pendingOnly: s.uri.queryParameters['pending'] == '1',
          ),
        ),
        routes: [
          GoRoute(
            path: ':id',
            redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.order),
            builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/customers/:id',
        redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.customer),
        builder: (_, s) => CustomerDetailScreen(customerId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => CustomerEditScreen(customerId: s.pathParameters['id']),
          ),
          GoRoute(
            path: 'rates',
            builder: (_, s) => CustomerRatesScreen(customerId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.newProduct, builder: (_, _) => const ProductEditScreen()),
      GoRoute(
        path: '/product/:id',
        redirect: (_, s) => _requireUuid(s, 'id', AppRoutes.maal),
        builder: (_, s) => ProductDetailScreen(productId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => ProductEditScreen(productId: s.pathParameters['id']),
          ),
        ],
      ),
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
            routes: [GoRoute(path: AppRoutes.maal, builder: (_, _) => const CatalogueScreen())],
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
  void openCustomer(String customerId) => _push(AppRoutes.customerDetail(customerId));
  @override
  void editCustomer([String? customerId]) => _push(AppRoutes.editCustomer(customerId));
  @override
  void openCustomerRates(String customerId) => _push(AppRoutes.customerRates(customerId));

  @override
  void openCart({String? customerId}) => _push(AppRoutes.cart(customerId: customerId));
  @override
  void openQuickOrder() => _push(AppRoutes.quickOrder);
  @override
  void openOrder(String orderId) => _push(AppRoutes.orderDetail(orderId));
  @override
  void openOrders({String? customerId, bool pendingOnly = false}) =>
      _push(AppRoutes.orders(customerId: customerId, pendingOnly: pendingOnly));

  @override
  void openHisaab(String customerId) => _push(AppRoutes.ledger(customerId));
  @override
  void openPayment(String customerId) => _push(AppRoutes.payment(customerId));
  @override
  void openReceipt(String paymentId) => _push(AppRoutes.receipt(paymentId));
  @override
  void openBill(String billId) => _push(AppRoutes.bill(billId));

  @override
  void openBusinessProfile() => _push(AppRoutes.businessProfile);
  @override
  void openStaff() => _push(AppRoutes.staff);
  @override
  void openAudit() => _push(AppRoutes.audit);
  @override
  void openExport() => _push(AppRoutes.export);
  @override
  void openNotifications() => _push(AppRoutes.notifications);

  @override
  void back() {
    if (_router.canPop()) _router.pop();
  }
}
