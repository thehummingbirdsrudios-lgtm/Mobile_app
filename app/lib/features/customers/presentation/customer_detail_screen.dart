import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/customer_providers.dart';
import '../domain/customers.dart';

/// Actions supplied by other modules (cart, vaat) through the app layer, so
/// this module never imports them.
class CustomerActions {
  const CustomerActions({this.onAddRegular, this.vaatBuilder});

  /// Adds a Regular Maal design to this customer's cart.
  final void Function(String customerId, RegularMaalItem item)? onAddRegular;
  final Widget Function(String customerId)? vaatBuilder;
}

final customerActionsProvider = Provider<CustomerActions>((ref) => const CustomerActions());

/// Everything about one customer on one screen: contact, Baki, open orders,
/// what they usually buy, and one tap to order.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(customerDetailProvider(customerId));
    return switch (detail) {
      AsyncData(:final value?) => _Body(customer: value),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off_rounded, title: l10n.commonNotFound),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.refresh(customerDetailProvider(customerId).future),
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
  const _Body({required this.customer});

  final CustomerDetail customer;

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref.read(contactLauncherProvider).call(customer.phone!);
    if (!ok && context.mounted) AppFeedback.show(context, l10n.callUnavailable, tone: FeedbackTone.error);
  }

  Future<void> _whatsapp(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref.read(contactLauncherProvider).whatsapp(customer.whatsappNumber!);
    if (!ok && context.mounted) AppFeedback.show(context, l10n.whatsappUnavailable, tone: FeedbackTone.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nav = ref.watch(appNavigatorProvider);
    final session = ref.watch(currentSessionProvider);
    final actions = ref.watch(customerActionsProvider);
    final c = customer;
    bool can(Permission p) => session?.can(p) ?? false;

    final quickActions = <(IconData, String, VoidCallback?)>[
      if (c.phone != null) (Icons.call_outlined, l10n.actionCall, () => _call(context, ref)),
      if (c.whatsappNumber != null) (Icons.chat_outlined, l10n.commonWhatsapp, () => _whatsapp(context, ref)),
      if (can(Permission.ordersCreate) && !c.isArchived)
        (Icons.add_shopping_cart_rounded, l10n.commonOrderKaro, () => nav.openCart(customerId: c.id)),
      if (can(Permission.paymentsRecord) && !c.isArchived)
        (Icons.currency_rupee_rounded, l10n.actionPayment, () => nav.openPayment(c.id)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (can(Permission.customersManage))
            IconButton(
              tooltip: l10n.commonEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => nav.editCustomer(c.id),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: () async {
          ref
            ..invalidate(regularMaalProvider(c.id))
            ..invalidate(customerDetailProvider(c.id));
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.goldTint,
                      foregroundColor: AppColors.goldText,
                      child: Text(
                        c.name.trim().isEmpty ? '?' : c.name.trim().characters.first.toUpperCase(),
                        style: text.headlineSmall!.copyWith(color: AppColors.goldText),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: text.titleLarge),
                          if (c.place != null) Text(c.place!, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                          if (c.phone != null)
                            Text(
                              c.phone!,
                              style: text.bodyMedium!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
                            ),
                        ],
                      ),
                    ),
                    if (c.isArchived) StatusChip(label: l10n.statusArchived),
                  ],
                ),
                if (quickActions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      for (final (icon, label, onTap) in quickActions)
                        Expanded(
                          child: _QuickAction(icon: icon, label: label, onTap: onTap),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (c.baki != null)
                  AppCard(
                    onTap: can(Permission.hisaabView) ? () => nav.openHisaab(c.id) : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.bakiLabel, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                              MoneyText(c.baki!, style: text.headlineMedium),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => nav.openHisaab(c.id),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(l10n.navHisaab),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: l10n.openOrdersLabel,
                        value: AppFormat.count(c.openOrders),
                        onTap: () => nav.openOrders(customerId: c.id, pendingOnly: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Stat(
                        label: l10n.totalOrdersLabel,
                        value: AppFormat.count(c.orderCount),
                        onTap: () => nav.openOrders(customerId: c.id),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Stat(
                        label: l10n.lastOrderLabel,
                        value: c.lastOrderAt == null ? l10n.neverLabel : AppFormat.shortDate(c.lastOrderAt!, locale),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.regularMaalTitle, style: text.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                _RegularMaal(customerId: c.id, onAdd: c.isArchived ? null : actions.onAddRegular),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  onTap: () => nav.openCustomerRates(c.id),
                  child: Row(
                    children: [
                      const Icon(Icons.sell_outlined, color: AppColors.goldText),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(l10n.specialRatesTitle, style: text.titleMedium)),
                      Text(
                        l10n.specialRatesCount(c.specialRates),
                        style: text.bodyMedium!.copyWith(color: AppColors.muted),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                ),
                if ((c.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.fieldNotes, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(c.notes!, style: text.bodyLarge),
                ],
                if (actions.vaatBuilder != null) ...[const SizedBox(height: AppSpacing.xl), actions.vaatBuilder!(c.id)],
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.control,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: AppColors.ink, foregroundColor: AppColors.onInk, child: Icon(icon, size: 22)),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodySmall!.copyWith(color: AppColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(value, style: text.titleLarge!.copyWith(fontFeatures: AppType.figures)),
        ],
      ),
    );
  }
}

class _RegularMaal extends ConsumerWidget {
  const _RegularMaal({required this.customerId, this.onAdd});

  final String customerId;
  final void Function(String customerId, RegularMaalItem item)? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final nav = ref.watch(appNavigatorProvider);
    final items = ref.watch(regularMaalProvider(customerId));
    return switch (items) {
      AsyncData(:final value) when value.isEmpty => Text(
        l10n.regularMaalEmpty,
        style: text.bodyMedium!.copyWith(color: AppColors.muted),
      ),
      AsyncData(:final value) => SizedBox(
        height: 236,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final item = value[i];
            return SizedBox(
              width: 150,
              child: ProductCard(
                image: RemoteImage(path: item.thumbPath, decodeWidth: 150, semanticLabel: item.name),
                designNo: item.designNo,
                name: l10n.regularMaalMeta(item.timesOrdered, item.lastQty),
                rate: item.rate,
                availabilityLabel: item.isOrderable ? l10n.productAvailable : l10n.productNotAvailable,
                isAvailable: item.isOrderable,
                onTap: () => nav.openProduct(item.productId),
                onAdd: onAdd != null && item.isOrderable ? () => onAdd!(customerId, item) : null,
                addLabel: l10n.commonAdd,
              ),
            );
          },
        ),
      ),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.refresh(regularMaalProvider(customerId).future),
      ),
      _ => const SizedBox(height: 236, child: Center(child: CircularProgressIndicator())),
    };
  }
}
