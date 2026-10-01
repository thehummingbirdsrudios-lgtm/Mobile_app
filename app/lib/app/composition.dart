import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/core.dart';
import '../features/auth/auth.dart';
import '../features/bills/bills.dart';
import '../features/catalogue/catalogue.dart';
import '../features/customers/customers.dart';
import '../features/orders/orders.dart';
import '../features/sharing/sharing.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Cross-module actions, composed here so feature modules never import each
/// other's screens or state: catalogue and customers get "add to order"
/// without depending on the orders module.
List<Override> crossModuleOverrides() => [
  orderActionsProvider.overrideWithValue(
    OrderActions(
      billSection: (order) => BillSection(orderId: order.id, billId: order.bill?.id, billNo: order.bill?.billNo),
    ),
  ),
  productActionsProvider.overrideWith((ref) {
    final canOrder = ref.watch(currentSessionProvider)?.can(Permission.ordersCreate) ?? false;
    Future<void> share(List<String> ids) async {
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await shareDesigns(context, ref.read(productSharerProvider), ids);
    }

    if (!canOrder) {
      return ProductActions(onShare: (p) => share([p.id]), onShareMany: (ps) => share([for (final p in ps) p.id]));
    }
    return ProductActions(
      onShare: (p) => share([p.id]),
      onShareMany: (ps) => share([for (final p in ps) p.id]),
      onAdd: (p) => _addToCart(ref, () => ref.read(cartProvider.notifier).addProduct(p.id)),
      onOrder: (p) async {
        final added = await _addToCart(ref, () => ref.read(cartProvider.notifier).addProduct(p.id), quiet: true);
        if (added) ref.read(appNavigatorProvider).openCart();
      },
    );
  }),
  customerActionsProvider.overrideWith((ref) {
    final canOrder = ref.watch(currentSessionProvider)?.can(Permission.ordersCreate) ?? false;
    if (!canOrder) return const CustomerActions();
    return CustomerActions(
      onAddRegular: (customerId, item) => _addToCart(ref, () async {
        final cart = ref.read(cartProvider.notifier);
        final draft = ref.read(cartProvider);
        if (draft.customerId != customerId) {
          // Regular Maal belongs to this customer: start their order.
          final name = ref.read(customerDetailProvider(customerId)).value?.name ?? '';
          if (draft.isEmpty) {
            await cart.selectCustomer(customerId, name);
          } else {
            cart.reset(customerId: customerId, customerName: name);
          }
        }
        cart.addQuoted(
          QuotedProduct(
            productId: item.productId,
            designNo: item.designNo,
            name: item.name,
            rate: item.rate,
            isOrderable: item.isOrderable,
            thumbPath: item.thumbPath,
          ),
          qty: item.lastQty,
        );
      }),
    );
  }),
];

/// Runs [add] and reports the outcome on the visible screen.
Future<bool> _addToCart(Ref ref, Future<void> Function() add, {bool quiet = false}) async {
  try {
    await add();
    final context = rootNavigatorKey.currentContext;
    if (!quiet && context != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      AppFeedback.show(
        context,
        l10n.addedToCart,
        actionLabel: l10n.goToCart,
        onAction: () => ref.read(appNavigatorProvider).openCart(),
      );
    }
    return true;
  } on Object catch (error) {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      AppFeedback.show(context, AppFailure.from(error).message(AppLocalizations.of(context)), tone: FeedbackTone.error);
    }
    return false;
  }
}
