import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/bills.dart';

/// The bill as the customer sees it. Rendered by Flutter (correct Gujarati
/// and Hindi shaping) and captured as an image for sharing.
class BillView extends StatelessWidget {
  const BillView({super.key, required this.bill});

  final BillDocument bill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final b = bill;
    final muted = text.bodySmall!.copyWith(color: AppColors.muted);
    final figures = text.bodyMedium!.copyWith(fontFeatures: AppType.figures);

    Widget totalRow(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? text.titleMedium : text.bodyMedium)),
          Text(value, style: (strong ? text.titleLarge! : text.bodyMedium!).copyWith(fontFeatures: AppType.figures)),
        ],
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (b.business.logoPath != null)
            Center(
              child: SizedBox.square(
                dimension: 56,
                child: RemoteImage(path: b.business.logoPath, bucket: Buckets.branding, fit: BoxFit.contain),
              ),
            ),
          Text(b.business.name, textAlign: TextAlign.center, style: text.titleLarge),
          if (b.business.address != null) Text(b.business.address!, textAlign: TextAlign.center, style: muted),
          if (b.business.phone != null || b.business.gstin != null)
            Text(
              [?b.business.phone, if (b.business.gstin != null) 'GSTIN ${b.business.gstin}'].join(' · '),
              textAlign: TextAlign.center,
              style: muted,
            ),
          const Divider(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.billTo, style: muted),
                    Text(b.customerName, style: text.titleMedium),
                    if (b.customerPhone != null) Text(b.customerPhone!, style: muted),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.billNumber('${b.billNo}'), style: text.titleMedium),
                  Text(AppFormat.fullDate(b.issuedAt, locale), style: muted),
                  Text(l10n.billOrderRef('${b.orderNo}'), style: muted),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
            color: AppColors.surfaceMuted,
            child: Row(
              children: [
                Expanded(child: Text(l10n.billColDesign, style: text.labelMedium)),
                _NumberCell(width: 40, text: l10n.billColQty, style: text.labelMedium!),
                _NumberCell(width: 70, text: l10n.billColRate, style: text.labelMedium!),
                _NumberCell(width: 84, text: l10n.billColAmount, style: text.labelMedium!),
              ],
            ),
          ),
          for (final item in b.items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox.square(
                      dimension: 40,
                      child: RemoteImage(path: item.thumbPath, decodeWidth: 120, semanticLabel: item.name),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.designNo, style: text.titleSmall!.copyWith(fontFeatures: AppType.figures)),
                        Text(item.name, style: muted, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _NumberCell(width: 40, text: '${item.qty}', style: figures),
                  _NumberCell(width: 70, text: item.rate.format(), style: figures),
                  _NumberCell(width: 84, text: item.amount.format(), style: figures),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          totalRow(l10n.billColQty, l10n.piecesCount(b.totalQty)),
          if ((b.totalWeightMg ?? 0) > 0) totalRow(l10n.billWeight, AppFormat.grams(b.totalWeightMg!)),
          totalRow(l10n.billTotal, b.total.format(), strong: true),
          if (!b.paid.isZero) totalRow(l10n.billPaid, b.paid.format()),
          const Divider(height: AppSpacing.lg),
          totalRow(
            l10n.billBakiAfter,
            b.balanceAfter.isNegative ? '${l10n.advanceLabel} ${(-b.balanceAfter).format()}' : b.balanceAfter.format(),
            strong: true,
          ),
          if ((b.business.footer ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(b.business.footer!, textAlign: TextAlign.center, style: muted),
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: b.business.watermark
          ? Stack(
              children: [
                content,
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          b.business.name,
                          style: text.displayMedium!.copyWith(color: AppColors.ink.withValues(alpha: 0.05)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : content,
    );
  }
}

/// A right-aligned number that shrinks rather than overflowing its column.
class _NumberCell extends StatelessWidget {
  const _NumberCell({required this.width, required this.text, required this.style});

  final double width;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(text, style: style, maxLines: 1),
    ),
  );
}
