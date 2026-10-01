import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../money/money.dart';

/// Money with tabular figures and Indian grouping.
class MoneyText extends StatelessWidget {
  const MoneyText(this.money, {super.key, this.style});

  final Money money;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Text(money.format(), style: base.copyWith(fontFeatures: AppType.figures), maxLines: 1);
  }
}

enum StatusTone { neutral, success, warning, error, info, accent }

/// Small status label. Tone is never the only signal: the text carries meaning.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StatusTone.neutral => (AppColors.surfaceMuted, AppColors.inkSoft),
      StatusTone.success => (AppColors.successTint, AppColors.success),
      StatusTone.warning => (AppColors.warningTint, AppColors.warning),
      StatusTone.error => (AppColors.errorTint, AppColors.error),
      StatusTone.info => (AppColors.infoTint, AppColors.info),
      StatusTone.accent => (AppColors.goldTint, AppColors.goldText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Elevated surface card used for every grouped surface (consistent radius/shadow).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(AppSpacing.md)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: AppRadius.card, boxShadow: AppElevation.low),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Photo-first product card: image, design no, name, rate, availability.
/// The photo takes the remaining height, so the card never overflows on
/// narrow phones or with large text; the image slot is supplied by the
/// caller (signed, cached thumbnail).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.designNo,
    required this.name,
    required this.rate,
    required this.availabilityLabel,
    required this.isAvailable,
    this.onTap,
    this.onAdd,
    this.addLabel,
  });

  final Widget image;
  final String designNo;
  final String name;
  final Money rate;
  final String availabilityLabel;
  final bool isAvailable;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppColors.surfaceMuted, child: image),
                if (onAdd != null)
                  Positioned(
                    right: AppSpacing.xxs,
                    bottom: AppSpacing.xxs,
                    child: IconButton.filled(
                      tooltip: addLabel,
                      onPressed: isAvailable ? onAdd : null,
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(kMinTouchTarget),
                        disabledBackgroundColor: AppColors.divider,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  designNo,
                  style: text.titleMedium!.copyWith(fontFeatures: AppType.figures),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(name, style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Flexible(child: MoneyText(rate, style: text.titleMedium)),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.circle, size: 8, color: isAvailable ? AppColors.success : AppColors.muted),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        availabilityLabel,
                        style: AppType.caption.copyWith(color: isAvailable ? AppColors.success : AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Customer row: name, secondary line, Baki on the right.
class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.name, this.subtitle, this.baki, this.onTap});

  final String name;
  final String? subtitle;
  final Money? baki;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.goldTint,
        foregroundColor: AppColors.goldText,
        child: Text(initial, style: text.titleMedium!.copyWith(color: AppColors.goldText)),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: baki == null
          ? null
          : MoneyText(
              baki!,
              style: text.titleMedium!.copyWith(color: baki!.paise > 0 ? AppColors.ink : AppColors.success),
            ),
    );
  }
}
