import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard.dart';

/// Where Home can send the user. The app shell maps these to routes, so this
/// module never depends on another module's screens.
enum HomeDestination { orders, payment, newMaal, hisaab }

/// "Namaskar Rajeshbhai 👋 / Aaje shu che?" — today's position in seconds,
/// then four quick actions. Not a 30-card dashboard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<HomeDestination> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final session = ref.watch(currentSessionProvider);
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
                sliver: SliverList.list(
                  children: [
                    Text(
                      l10n.greeting(session?.displayName ?? ''),
                      style: text.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (session != null)
                      Text(session.businessName, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              if (session?.can(Permission.reportsView) ?? false)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.homeTodayQuestion, style: text.titleLarge),
                        const SizedBox(height: AppSpacing.sm),
                        switch (summary) {
                          AsyncData(:final value?) => _StatsGrid(summary: value, onNavigate: onNavigate),
                          AsyncError(:final error) => SizedBox(
                            height: 220,
                            child: ErrorState(
                              failure: AppFailure.from(error),
                              onRetry: () => ref.refresh(dashboardSummaryProvider.future),
                            ),
                          ),
                          _ => const _StatsSkeleton(),
                        },
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.quickActions, style: text.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      _QuickActions(onNavigate: onNavigate),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary, required this.onNavigate});

  final DashboardSummary summary;
  final ValueChanged<HomeDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _TwoByTwo(
      children: [
        _StatTile(
          value: summary.salesToday.format(),
          label: l10n.statSalesToday,
          onTap: () => onNavigate(HomeDestination.orders),
        ),
        _StatTile(
          value: summary.paymentsToday.format(),
          label: l10n.statPaymentsToday,
          onTap: () => onNavigate(HomeDestination.hisaab),
        ),
        _StatTile(
          value: summary.totalBaki.format(),
          label: l10n.statTotalBaki,
          emphasis: true,
          onTap: () => onNavigate(HomeDestination.hisaab),
        ),
        _StatTile(
          value: AppFormat.count(summary.pendingOrders),
          label: l10n.statPendingOrders,
          onTap: () => onNavigate(HomeDestination.orders),
        ),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: _TwoByTwo(
        children: List.generate(
          4,
          (_) => const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 110, height: 28),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 80, height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2×2 grid that keeps equal tile heights without fixed sizes (long
/// Gujarati/Hindi labels can wrap without clipping).
class _TwoByTwo extends StatelessWidget {
  const _TwoByTwo({required this.children}) : assert(children.length == 4);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: b),
        ],
      ),
    );
    return Column(
      children: [
        row(children[0], children[1]),
        const SizedBox(height: AppSpacing.sm),
        row(children[2], children[3]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.onTap, this.emphasis = false});

  final String value;
  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.headlineSmall!.copyWith(
                  fontFeatures: AppType.figures,
                  color: emphasis ? AppColors.goldText : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});

  final ValueChanged<HomeDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = [
      (Icons.receipt_long_rounded, l10n.actionOrder, HomeDestination.orders),
      (Icons.payments_rounded, l10n.actionPayment, HomeDestination.payment),
      (Icons.auto_awesome_rounded, l10n.actionNewMaal, HomeDestination.newMaal),
      (Icons.account_balance_wallet_rounded, l10n.actionHisaab, HomeDestination.hisaab),
    ];
    return Row(
      children: [
        for (final (icon, label, destination) in actions)
          Expanded(
            child: _QuickAction(icon: icon, label: label, onTap: () => onNavigate(destination)),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  boxShadow: AppElevation.low,
                ),
                child: Icon(icon, color: AppColors.goldText),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
