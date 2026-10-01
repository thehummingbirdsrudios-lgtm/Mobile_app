import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/catalogue.dart';

/// Hero tag shared by the grid thumbnail and the detail gallery.
String productHeroTag(String productId) => 'product-image-$productId';

/// Catalogue grid card: photo, design no, name, rate, availability.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap, this.onAdd, this.selected});

  final ProductSummary product;
  final VoidCallback onTap;

  /// Quick "add to order" (+). Null hides the button.
  final VoidCallback? onAdd;

  /// Non-null shows a selection check (multi-select mode).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = ProductCard(
      image: Hero(
        tag: productHeroTag(product.id),
        child: RemoteImage(path: product.thumbPath, decodeWidth: 220, semanticLabel: product.name),
      ),
      designNo: product.designNo,
      name: product.name,
      rate: product.rate,
      availabilityLabel: product.isAvailable ? l10n.productAvailable : l10n.productNotAvailable,
      isAvailable: product.isAvailable,
      onTap: onTap,
      onAdd: onAdd,
      addLabel: l10n.commonAdd,
    );
    if (selected == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.quick),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected! ? AppColors.ink : AppColors.surface.withValues(alpha: 0.9),
                border: Border.all(color: selected! ? AppColors.ink : AppColors.divider, width: 1.5),
              ),
              child: selected! ? const Icon(Icons.check_rounded, size: 18, color: AppColors.onInk) : null,
            ),
          ),
        ),
      ],
    );
  }
}
