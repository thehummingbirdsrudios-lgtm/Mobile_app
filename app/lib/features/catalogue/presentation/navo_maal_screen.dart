import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/catalogue_providers.dart';
import '../domain/catalogue.dart';
import 'catalogue_screen.dart';
import 'product_detail_screen.dart';
import 'product_tile.dart';

/// Designs added in the last 7 days. The main job here is sending new maal
/// to customers, so selection-to-share is one tap away.
class NavoMaalScreen extends ConsumerStatefulWidget {
  const NavoMaalScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  /// WhatsApp handles about this many images comfortably in one send.
  static const maxShare = 10;

  @override
  ConsumerState<NavoMaalScreen> createState() => _NavoMaalScreenState();
}

class _NavoMaalScreenState extends ConsumerState<NavoMaalScreen> {
  // Fixed for the life of the screen so paging keeps one window.
  late final _filter = CatalogueFilter.navoMaal(widget.clock());
  final _selected = <String, ProductSummary>{};
  bool _selecting = false;

  void _toggle(ProductSummary p) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (_selected.remove(p.id) == null) {
        if (_selected.length >= NavoMaalScreen.maxShare) {
          AppFeedback.show(context, l10n.selectionLimit(NavoMaalScreen.maxShare), tone: FeedbackTone.warning);
          return;
        }
        _selected[p.id] = p;
      }
    });
  }

  void _endSelection() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  Future<void> _share(ProductActions actions) async {
    await actions.onShareMany!(_selected.values.toList());
    if (mounted) _endSelection();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final nav = ref.watch(appNavigatorProvider);
    final actions = ref.watch(productActionsProvider);
    final canManage = ref.watch(currentSessionProvider)?.can(Permission.catalogueManage) ?? false;
    final feed = ref.watch(catalogueFeedProvider(_filter));
    final notifier = ref.read(catalogueFeedProvider(_filter).notifier);
    final canShare = actions.onShareMany != null;

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelection();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _selecting
              ? IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _endSelection,
                )
              : null,
          title: _selecting
              ? Text(l10n.selectionCount(_selected.length))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.actionNewMaal),
                    Text(l10n.navoMaalSubtitle, style: text.bodySmall!.copyWith(color: AppColors.muted)),
                  ],
                ),
        ),
        bottomNavigationBar: canShare && (feed.items.isNotEmpty)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xs,
                    AppSpacing.gutter,
                    AppSpacing.sm,
                  ),
                  child: _selecting
                      ? AppButton(
                          label: l10n.shareSelected(_selected.length),
                          icon: Icons.share_rounded,
                          onPressed: _selected.isEmpty ? null : () => _share(actions),
                        )
                      : AppButton(
                          label: l10n.selectToShare,
                          icon: Icons.checklist_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => setState(() => _selecting = true),
                        ),
                ),
              )
            : null,
        body: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            slivers: [
              PagedSliverBody<ProductSummary, CatalogueCursor>(
                state: feed,
                padding: const EdgeInsets.all(AppSpacing.gutter),
                gridDelegate: catalogueGridDelegate,
                onLoadMore: notifier.loadMore,
                onRetry: notifier.retry,
                itemBuilder: (context, p) => ProductTile(
                  product: p,
                  selected: _selecting ? _selected.containsKey(p.id) : null,
                  onTap: _selecting ? () => _toggle(p) : () => nav.openProduct(p.id),
                  onAdd: _selecting || actions.onAdd == null ? null : () => actions.onAdd!(p),
                ),
                skeleton: const CatalogueSkeleton(),
                empty: EmptyState(
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.navoMaalEmpty,
                  actionLabel: canManage ? l10n.productAdd : null,
                  onAction: canManage ? nav.editProduct : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
