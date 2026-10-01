import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/search_controller.dart';
import '../domain/search.dart';

/// One search box for designs, customers and orders. Opens with the keyboard
/// up; recent searches show until the user types.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _useRecent(String query) {
    _text
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    unawaited(ref.read(searchControllerProvider.notifier).setQuery(query));
  }

  void _open(SearchHit hit) {
    final controller = ref.read(searchControllerProvider.notifier);
    final nav = ref.read(appNavigatorProvider);
    unawaited(controller.remember(ref.read(searchControllerProvider).query));
    switch (hit.kind) {
      case SearchKind.product:
        nav.openProduct(hit.id);
      case SearchKind.customer:
        nav.openCustomer(hit.id);
      case SearchKind.order:
        nav.openOrder(hit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    final Widget body;
    if (state.query.isEmpty) {
      body = _Recent(recent: state.recent, onTap: _useRecent, onClear: controller.clearRecent);
    } else if (state.failure != null) {
      body = ErrorState(failure: state.failure!, onRetry: controller.retry);
    } else if (state.results == null) {
      body = const SizedBox.shrink();
    } else if (state.results!.isEmpty && !state.isLoading) {
      body = EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.searchNoMatch(state.query),
        body: l10n.searchNoMatchBody,
      );
    } else {
      body = _Results(results: state.results!, onOpen: _open);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: AppSearchField(
            hint: l10n.searchHint,
            controller: _text,
            autofocus: true,
            debounce: const Duration(milliseconds: 300),
            onQuery: controller.setQuery,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: state.isLoading
              ? const LinearProgressIndicator(minHeight: 2, color: AppColors.ink)
              : const SizedBox(height: 2),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: AnimatedSwitcher(duration: AppMotion.of(context, AppMotion.quick), child: body),
        ),
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.recent, required this.onTap, required this.onClear});

  final List<String> recent;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          l10n.searchStartHint,
          textAlign: TextAlign.center,
          style: text.bodyLarge!.copyWith(color: AppColors.muted),
        ),
      );
    }
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.xs, 0),
          child: Row(
            children: [
              Expanded(child: Text(l10n.searchRecent, style: text.titleMedium)),
              TextButton(onPressed: onClear, child: Text(l10n.searchClearRecent)),
            ],
          ),
        ),
        for (final q in recent)
          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppColors.muted),
            title: Text(q),
            onTap: () => onTap(q),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.results, required this.onOpen});

  final SearchResults results;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        if (results.products.isNotEmpty) ...[
          _Header(l10n.searchSectionDesigns),
          for (final h in results.products)
            _HitTile(hit: h, icon: Icons.diamond_outlined, title: h.title, onOpen: onOpen),
        ],
        if (results.customers.isNotEmpty) ...[
          _Header(l10n.searchSectionCustomers),
          for (final h in results.customers)
            _HitTile(hit: h, icon: Icons.storefront_outlined, title: h.title, onOpen: onOpen),
        ],
        if (results.orders.isNotEmpty) ...[
          _Header(l10n.searchSectionOrders),
          for (final h in results.orders)
            _HitTile(hit: h, icon: Icons.receipt_long_outlined, title: l10n.orderNumberTitle(h.title), onOpen: onOpen),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xxs),
    child: Semantics(
      header: true,
      child: Text(label, style: AppType.label.copyWith(color: AppColors.muted)),
    ),
  );
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.icon, required this.title, required this.onOpen});

  final SearchHit hit;
  final IconData icon;
  final String title;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: AppColors.surfaceMuted,
      foregroundColor: AppColors.ink,
      child: Icon(icon, size: 20),
    ),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: hit.subtitle == null ? null : Text(hit.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    onTap: () => onOpen(hit),
  );
}
