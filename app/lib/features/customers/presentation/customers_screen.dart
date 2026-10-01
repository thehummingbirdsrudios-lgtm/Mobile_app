import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/customer_providers.dart';
import '../domain/customers.dart';

/// Customer tab: find a customer fast (name or mobile), see who owes most.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  var _query = const CustomerQuery();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nav = ref.watch(appNavigatorProvider);
    final session = ref.watch(currentSessionProvider);
    final canManage = session?.can(Permission.customersManage) ?? false;
    final canSeeBaki = session?.can(Permission.hisaabView) ?? false;
    final list = ref.watch(customerListProvider(_query));
    final notifier = ref.read(customerListProvider(_query).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCustomer)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: nav.editCustomer,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.customerAdd),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: RefreshIndicator(
            color: AppColors.ink,
            onRefresh: notifier.refresh,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
                    child: AppSearchField(
                      hint: l10n.customerSearchHint,
                      onQuery: (q) => setState(() => _query = CustomerQuery(search: q, sort: _query.sort)),
                    ),
                  ),
                ),
                if (canSeeBaki)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          for (final (sort, label) in [
                            (CustomerSort.name, l10n.sortAZ),
                            (CustomerSort.baki, l10n.sortBaki),
                          ])
                            ChoiceChip(
                              label: Text(label),
                              selected: _query.sort == sort,
                              onSelected: (_) =>
                                  setState(() => _query = CustomerQuery(search: _query.search, sort: sort)),
                            ),
                        ],
                      ),
                    ),
                  ),
                PagedSliverBody<CustomerSummary, CustomerCursor>(
                  state: list,
                  padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.huge * 2),
                  onLoadMore: notifier.loadMore,
                  onRetry: notifier.retry,
                  itemBuilder: (context, c) => CustomerTile(
                    name: c.name,
                    subtitle: c.place ?? c.phone,
                    baki: c.baki,
                    onTap: () => nav.openCustomer(c.id),
                  ),
                  skeleton: const _ListSkeleton(),
                  empty: _query.search.isEmpty
                      ? EmptyState(
                          icon: Icons.people_alt_outlined,
                          title: l10n.customersEmpty,
                          actionLabel: canManage ? l10n.customerAdd : null,
                          onAction: canManage ? nav.editCustomer : null,
                        )
                      : EmptyState(icon: Icons.search_off_rounded, title: l10n.customersNoMatch(_query.search)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < 6; i++)
          const ListTile(
            leading: SkeletonBox(width: 40, height: 40, radius: 20),
            title: SkeletonBox(width: 140, height: 16),
            subtitle: SkeletonBox(width: 90, height: 12),
          ),
      ],
    ),
  );
}
