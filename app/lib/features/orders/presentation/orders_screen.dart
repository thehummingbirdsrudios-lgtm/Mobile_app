import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/order_providers.dart';
import '../domain/orders.dart';
import 'order_labels.dart';

/// Order tab: pending first (what needs doing), all orders one tap away.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _pendingOnly = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nav = ref.watch(appNavigatorProvider);
    final canCreate = ref.watch(currentSessionProvider)?.can(Permission.ordersCreate) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navOrder),
        actions: [
          if (canCreate)
            TextButton.icon(
              onPressed: nav.openQuickOrder,
              icon: const Icon(Icons.bolt_rounded),
              label: Text(l10n.quickOrder),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: nav.openCart,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(l10n.orderNew),
            )
          : null,
      body: OrderListView(
        query: OrderQuery(pendingOnly: _pendingOnly),
        header: Wrap(
          spacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: Text(l10n.ordersPending),
              selected: _pendingOnly,
              onSelected: (_) => setState(() => _pendingOnly = true),
            ),
            ChoiceChip(
              label: Text(l10n.ordersAll),
              selected: !_pendingOnly,
              onSelected: (_) => setState(() => _pendingOnly = false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders for one customer (from the customer screen).
class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key, required this.query, this.title});

  final OrderQuery query;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title ?? (query.pendingOnly ? l10n.ordersPending : l10n.navOrder))),
      body: OrderListView(query: query, showCustomer: query.customerId == null),
    );
  }
}

class OrderListView extends ConsumerWidget {
  const OrderListView({super.key, required this.query, this.header, this.showCustomer = true});

  final OrderQuery query;
  final Widget? header;
  final bool showCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nav = ref.watch(appNavigatorProvider);
    final list = ref.watch(orderListProvider(query));
    final notifier = ref.read(orderListProvider(query).notifier);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            slivers: [
              if (header != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
                    child: header,
                  ),
                ),
              PagedSliverBody<OrderSummary, OrderCursor>(
                state: list,
                padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.huge * 2),
                onLoadMore: notifier.loadMore,
                onRetry: notifier.retry,
                itemBuilder: (context, o) =>
                    OrderTile(order: o, showCustomer: showCustomer, onTap: () => nav.openOrder(o.id)),
                skeleton: const _Skeleton(),
                empty: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: query.pendingOnly ? l10n.ordersPendingEmpty : l10n.ordersEmpty,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap, this.showCustomer = true});

  final OrderSummary order;
  final VoidCallback onTap;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final o = order;
    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Flexible(
            child: Text(
              showCustomer ? o.customerName : l10n.orderNumberTitle('${o.orderNo}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          StatusChip(label: orderStatusLabel(l10n, o.status), tone: orderStatusTone(o.status)),
        ],
      ),
      subtitle: Text(
        [
          if (showCustomer) '#${o.orderNo}',
          AppFormat.shortDate(o.createdAt, locale),
          l10n.piecesCount(o.totalQty),
        ].join(' · '),
        style: text.bodySmall!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
      ),
      trailing: MoneyText(
        o.total,
        style: text.titleMedium!.copyWith(
          decoration: o.status == OrderStatus.cancelled ? TextDecoration.lineThrough : null,
          color: o.status == OrderStatus.cancelled ? AppColors.muted : null,
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < 6; i++)
          const ListTile(
            title: SkeletonBox(width: 160, height: 16),
            subtitle: SkeletonBox(width: 110, height: 12),
            trailing: SkeletonBox(width: 64, height: 18),
          ),
      ],
    ),
  );
}
