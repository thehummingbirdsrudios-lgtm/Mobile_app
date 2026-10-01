import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/catalogue_providers.dart';
import '../domain/catalogue.dart';
import 'product_detail_screen.dart';
import 'product_tile.dart';

/// Maal: photo-first grid. Category chips + Navo Maal shortcut; search lives
/// in the app bar; managers get one "Add design" action.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String? _categoryId;

  CatalogueFilter get _filter => CatalogueFilter(categoryId: _categoryId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nav = ref.watch(appNavigatorProvider);
    final session = ref.watch(currentSessionProvider);
    final canManage = session?.can(Permission.catalogueManage) ?? false;
    final feed = ref.watch(catalogueFeedProvider(_filter));
    final notifier = ref.read(catalogueFeedProvider(_filter).notifier);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final onAdd = ref.watch(productActionsProvider).onAdd;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMaal),
        actions: [
          IconButton(tooltip: l10n.searchHint, icon: const Icon(Icons.search_rounded), onPressed: nav.openSearch),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: nav.editProduct,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.productAdd),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs),
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.goldText),
                      label: Text(l10n.actionNewMaal),
                      onPressed: nav.openNavoMaal,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      label: Text(l10n.catalogueAll),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    for (final c in categories) ...[
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            PagedSliverBody<ProductSummary, CatalogueCursor>(
              state: feed,
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 0),
              gridDelegate: catalogueGridDelegate,
              onLoadMore: notifier.loadMore,
              onRetry: notifier.retry,
              itemBuilder: (context, p) => ProductTile(
                product: p,
                onTap: () => nav.openProduct(p.id),
                onAdd: onAdd == null ? null : () => onAdd(p),
              ),
              skeleton: const CatalogueSkeleton(),
              empty: EmptyState(
                icon: Icons.diamond_outlined,
                title: l10n.catalogueEmpty,
                actionLabel: canManage ? l10n.catalogueEmptyOwnerAction : null,
                onAction: canManage ? nav.editProduct : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2 columns on phones, more on tablets; cards keep the jewellery photo square.
const catalogueGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisSpacing: AppSpacing.sm,
  crossAxisSpacing: AppSpacing.sm,
  childAspectRatio: 0.66,
);

class CatalogueSkeleton extends StatelessWidget {
  const CatalogueSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: catalogueGridDelegate,
        itemCount: 6,
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: SkeletonBox(height: double.infinity, radius: AppRadius.lg),
            ),
            SizedBox(height: AppSpacing.xs),
            SkeletonBox(width: 60, height: 16),
            SizedBox(height: AppSpacing.xxs),
            SkeletonBox(width: 100, height: 12),
            SizedBox(height: AppSpacing.xxs),
            SkeletonBox(width: 70, height: 16),
          ],
        ),
      ),
    );
  }
}
