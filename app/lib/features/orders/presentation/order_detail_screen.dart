import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/cart_controller.dart';
import '../application/order_providers.dart';
import '../domain/orders.dart';
import 'order_labels.dart';

/// Sections supplied by other modules (bill, share, vaat) via the app layer.
class OrderActions {
  const OrderActions({this.billSection, this.onShare, this.vaatBuilder});

  final Widget Function(OrderDetail order)? billSection;
  final Future<void> Function(OrderDetail order)? onShare;
  final Widget Function(String orderId)? vaatBuilder;
}

final orderActionsProvider = Provider<OrderActions>((ref) => const OrderActions());

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(orderDetailProvider(orderId))) {
      AsyncData(:final value?) => _Body(order: value),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off_rounded, title: l10n.commonNotFound),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.refresh(orderDetailProvider(orderId).future),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});

  final OrderDetail order;

  Future<void> _transition(BuildContext context, WidgetRef ref, OrderStatus to) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(orderManagerProvider).transition(order.id, to);
      if (context.mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await showTextInputDialog(
      context,
      title: l10n.cancelOrder,
      message: l10n.cancelOrderBody,
      label: l10n.cancelReason,
      confirmLabel: l10n.cancelOrder,
      cancelLabel: l10n.keepOrder,
      maxLength: 400,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(orderManagerProvider).cancel(order.id, reason: reason);
      if (context.mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  /// Fari Order: the same designs and quantities at TODAY's rates.
  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final nav = ref.read(appNavigatorProvider);
    try {
      final preview = await ref.read(ordersRepositoryProvider).reorderPreview(order.id);
      ref
          .read(cartProvider.notifier)
          .reset(
            customerId: order.customer.id,
            customerName: order.customer.name,
            reorderOf: order.id,
            lines: [
              for (final l in preview)
                CartLine(
                  productId: l.productId,
                  designNo: l.designNo,
                  name: l.name,
                  rate: l.rate,
                  qty: l.qty,
                  isOrderable: l.isOrderable,
                  thumbPath: l.thumbPath,
                ),
            ],
          );
      nav.openCart(customerId: order.customer.id);
    } on AppFailure catch (f) {
      if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nav = ref.watch(appNavigatorProvider);
    final session = ref.watch(currentSessionProvider);
    final actions = ref.watch(orderActionsProvider);
    final o = order;
    final canManage = session?.can(Permission.ordersManage) ?? false;
    final canCreate = session?.can(Permission.ordersCreate) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderNumberTitle('${o.orderNo}')),
        actions: [
          if (actions.onShare != null && o.status != OrderStatus.cancelled)
            IconButton(
              tooltip: l10n.commonShare,
              icon: const Icon(Icons.share_rounded),
              onPressed: () => actions.onShare!(o),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              Row(
                children: [
                  StatusChip(label: orderStatusLabel(l10n, o.status), tone: orderStatusTone(o.status)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      [
                        AppFormat.dateTime(o.createdAt, locale),
                        if (o.createdByName != null) l10n.orderCreatedBy(o.createdByName!),
                      ].join(' · '),
                      style: text.bodySmall!.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              if (o.cancelReason != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.orderCancelledReason(o.cancelReason!), style: text.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.md),
              AppCard(
                onTap: () => nav.openCustomer(o.customer.id),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: AppColors.goldText),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.customer.name, style: text.titleMedium),
                          if (o.customer.city != null)
                            Text(o.customer.city!, style: text.bodySmall!.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final line in o.items) _ItemRow(line: line),
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        l10n.piecesCount(o.totalQty),
                        if ((o.totalWeightMg ?? 0) > 0) AppFormat.grams(o.totalWeightMg!),
                      ].join(' · '),
                      style: text.bodyMedium!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
                    ),
                  ),
                  Text('${l10n.cartTotal} ', style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                  MoneyText(
                    o.total,
                    style: text.headlineSmall!.copyWith(
                      decoration: o.status == OrderStatus.cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              if ((o.note ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.fieldNotes, style: text.titleSmall),
                Text(o.note!, style: text.bodyLarge),
              ],
              if (o.payments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.orderPayments, style: text.titleMedium),
                for (final p in o.payments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.currency_rupee_rounded, color: AppColors.success),
                    title: Text(l10n.receiptNumber('${p.paymentNo}')),
                    subtitle: Text('${paymentModeLabel(l10n, p.mode)} · ${AppFormat.shortDate(p.receivedAt, locale)}'),
                    trailing: MoneyText(p.amount, style: text.titleMedium),
                  ),
              ],
              if (actions.billSection != null && o.status != OrderStatus.cancelled) ...[
                const SizedBox(height: AppSpacing.lg),
                actions.billSection!(o),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (canManage)
                for (final next in o.status.forward)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppButton(
                      label: l10n.markAs(orderStatusLabel(l10n, next)),
                      variant: next == o.status.forward.first ? AppButtonVariant.primary : AppButtonVariant.secondary,
                      onPressed: () => _transition(context, ref, next),
                    ),
                  ),
              if (canCreate)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppButton(
                    label: l10n.reorderAction,
                    icon: Icons.replay_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _reorder(context, ref),
                  ),
                ),
              if (canManage && o.status.canCancel)
                AppButton(
                  label: l10n.cancelOrder,
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.quiet,
                  // Opens a dialog: the button must not stay busy behind it.
                  onPressed: () => unawaited(_cancel(context, ref)),
                ),
              if (actions.vaatBuilder != null) ...[const SizedBox(height: AppSpacing.xl), actions.vaatBuilder!(o.id)],
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.control,
            child: SizedBox.square(
              dimension: 48,
              child: RemoteImage(path: line.thumbPath, decodeWidth: 48, semanticLabel: line.name),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.designNo, style: text.titleSmall!.copyWith(fontFeatures: AppType.figures)),
                Text(
                  '${line.qty} × ${line.rate.format()}',
                  style: text.bodySmall!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
                ),
              ],
            ),
          ),
          MoneyText(line.amount, style: text.titleMedium),
        ],
      ),
    );
  }
}
