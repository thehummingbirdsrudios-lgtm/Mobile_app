import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../../customers/customers.dart';

/// Hisaab tab: who owes how much, highest first. Only for hisaab.view.
class HisaabScreen extends ConsumerStatefulWidget {
  const HisaabScreen({super.key});

  @override
  ConsumerState<HisaabScreen> createState() => _HisaabScreenState();
}

class _HisaabScreenState extends ConsumerState<HisaabScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nav = ref.watch(appNavigatorProvider);
    final canView = ref.watch(currentSessionProvider)?.can(Permission.hisaabView) ?? false;
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navHisaab)),
        body: EmptyState(icon: Icons.lock_outline_rounded, title: l10n.hisaabNoPermission),
      );
    }
    final query = CustomerQuery(search: _search, sort: CustomerSort.baki);
    final list = ref.watch(customerListProvider(query));
    final notifier = ref.read(customerListProvider(query).notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHisaab)),
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
                    child: AppSearchField(hint: l10n.customerSearchHint, onQuery: (q) => setState(() => _search = q)),
                  ),
                ),
                PagedSliverBody<CustomerSummary, Object?>(
                  state: list,
                  padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.huge),
                  onLoadMore: notifier.loadMore,
                  onRetry: notifier.retry,
                  itemBuilder: (context, c) => CustomerTile(
                    name: c.name,
                    subtitle: c.place ?? c.phone,
                    baki: c.baki,
                    onTap: () => nav.openHisaab(c.id),
                  ),
                  skeleton: const Center(
                    child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
                  ),
                  empty: _search.isEmpty
                      ? EmptyState(icon: Icons.verified_outlined, title: l10n.hisaabAllClear)
                      : EmptyState(icon: Icons.search_off_rounded, title: l10n.customersNoMatch(_search)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
