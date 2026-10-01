import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/tokens.dart';
import '../state/paged.dart';
import 'states.dart';

/// Standard infinite list/grid body: skeleton while the first page loads,
/// empty state, error state with retry, inline "load more" and inline retry.
/// Loads the next page when the user nears the end.
class PagedSliverBody<T, C> extends StatelessWidget {
  const PagedSliverBody({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRetry,
    required this.empty,
    required this.skeleton,
    this.gridDelegate,
    this.padding = EdgeInsets.zero,
  });

  final PagedState<T, C> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRetry;
  final Widget empty;
  final Widget skeleton;
  final SliverGridDelegate? gridDelegate;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingFirst && state.items.isEmpty) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(child: skeleton),
      );
    }
    if (state.items.isEmpty && state.failure != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorState(failure: state.failure!, onRetry: onRetry),
      );
    }
    if (state.isEmpty) return SliverFillRemaining(hasScrollBody: false, child: empty);

    Widget item(BuildContext context, int index) {
      if (index >= state.items.length - 6) WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
      return itemBuilder(context, state.items[index]);
    }

    final list = gridDelegate == null
        ? SliverList.builder(itemCount: state.items.length, itemBuilder: item)
        : SliverGrid.builder(gridDelegate: gridDelegate!, itemCount: state.items.length, itemBuilder: item);

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(padding: padding, sliver: list),
        SliverToBoxAdapter(
          child: _Footer(state: state, onRetry: onRetry),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final PagedState<Object?, Object?> state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.failure != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context).retry),
          ),
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.2))),
      );
    }
    return const SizedBox(height: AppSpacing.huge);
  }
}
