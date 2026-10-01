import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/catalogue_providers.dart';
import '../domain/catalogue.dart';
import 'product_tile.dart';

/// Optional actions supplied by other modules (order, share, vaat) so this
/// module does not depend on them.
class ProductActions {
  const ProductActions({this.onOrder, this.onShare, this.vaatBuilder});

  final void Function(ProductDetail product)? onOrder;
  final void Function(ProductDetail product)? onShare;
  final Widget Function(ProductDetail product)? vaatBuilder;
}

final productActionsProvider = Provider<ProductActions>((ref) => const ProductActions());

/// Large photo first, then design no, rate, availability. Few words.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(productDetailProvider(productId));
    return switch (detail) {
      AsyncData(:final value?) => _DetailBody(product: value),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off_rounded, title: l10n.commonNotFound),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.refresh(productDetailProvider(productId).future),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: _DetailSkeleton(productId: productId),
      ),
    };
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.product});

  final ProductDetail product;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = widget.product;
    final session = ref.watch(currentSessionProvider);
    final actions = ref.watch(productActionsProvider);
    final canManage = session?.can(Permission.catalogueManage) ?? false;
    final width = MediaQuery.sizeOf(context).width;
    final galleryHeight = (width > AppSpacing.maxListWidth ? AppSpacing.maxListWidth : width);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: galleryHeight,
            backgroundColor: AppColors.surfaceMuted,
            actions: [
              if (canManage)
                IconButton(
                  tooltip: l10n.commonEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => ref.read(appNavigatorProvider).editProduct(p.id),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (p.photos.isEmpty)
                    Hero(tag: productHeroTag(p.id), child: const RemoteImage(path: null))
                  else
                    PageView.builder(
                      itemCount: p.photos.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        final image = RemoteImage(
                          path: p.photos[i].cataloguePath ?? p.photos[i].thumbPath,
                          fit: BoxFit.contain,
                          decodeWidth: galleryHeight,
                          semanticLabel: '${p.designNo} ${p.name}',
                        );
                        return i == 0 ? Hero(tag: productHeroTag(p.id), child: image) : image;
                      },
                    ),
                  if (p.photos.length > 1)
                    Positioned(
                      bottom: AppSpacing.md,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < p.photos.length; i++)
                            AnimatedContainer(
                              duration: AppMotion.of(context, AppMotion.quick),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _page ? AppColors.ink : AppColors.divider,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.designNo, style: text.headlineSmall!.copyWith(fontFeatures: AppType.figures)),
                      Text(p.name, style: text.bodyLarge!.copyWith(color: AppColors.muted)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MoneyText(p.rate, style: text.displaySmall),
                          const SizedBox(width: AppSpacing.xs),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(l10n.perPiece, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          StatusChip(
                            label: p.isArchived
                                ? l10n.productArchived
                                : (p.isAvailable ? l10n.productAvailable : l10n.productNotAvailable),
                            tone: p.isOrderable ? StatusTone.success : StatusTone.neutral,
                          ),
                          if (p.categoryName != null) StatusChip(label: p.categoryName!, tone: StatusTone.accent),
                        ],
                      ),
                      if (p.weightMg != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('${l10n.weightLabel}: ${AppFormat.grams(p.weightMg!)}', style: text.bodyLarge),
                      ],
                      if ((p.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(p.description!, style: text.bodyLarge),
                      ],
                      if (p.private != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _PrivateCard(private: p.private!),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      if (actions.onOrder != null)
                        AppButton(
                          label: l10n.commonOrderKaro,
                          icon: Icons.add_shopping_cart_rounded,
                          onPressed: p.isOrderable ? () => actions.onOrder!(p) : null,
                        ),
                      if (actions.onShare != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: l10n.commonShare,
                          icon: Icons.share_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: p.isArchived ? null : () => actions.onShare!(p),
                        ),
                      ],
                      if (actions.vaatBuilder != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        actions.vaatBuilder!(p),
                      ],
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateCard extends StatelessWidget {
  const _PrivateCard({required this.private});

  final ProductPrivate private;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
          ),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.goldTint.withValues(alpha: 0.5),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.goldTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.goldText),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.ownerOnlySection, style: text.labelLarge!.copyWith(color: AppColors.goldText)),
            ],
          ),
          if (private.cost != null) row(l10n.fieldCost, private.cost!.format()),
          if ((private.supplierName ?? '').isNotEmpty) row(l10n.fieldSupplier, private.supplierName!),
          if ((private.internalNote ?? '').isNotEmpty) row(l10n.fieldInternalNote, private.internalNote!),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Hero(tag: productHeroTag(productId), child: const RemoteImage(path: null)),
        ),
        const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 90, height: 28),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 160, height: 16),
                SizedBox(height: AppSpacing.lg),
                SkeletonBox(width: 120, height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
