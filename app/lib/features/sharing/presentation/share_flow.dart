import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/product_sharer.dart';
import '../domain/sharing.dart';

/// Localised caption: one block per design, then the business signature.
String buildShareCaption(AppLocalizations l10n, List<ShareableProduct> products, ShareOptions options) {
  final lines = <String>[];
  for (final p in products) {
    lines.add('${p.designNo} · ${p.name}');
    final details = [
      if (options.showRate) l10n.shareRateLine(p.rate.format()),
      if (p.weightMg != null) AppFormat.grams(p.weightMg!),
    ];
    if (details.isNotEmpty) lines.add(details.join(' · '));
    lines.add('');
  }
  if (products.isNotEmpty) {
    final business = products.first;
    lines.add('— ${business.businessName}');
    if (business.whatsappPhone != null) lines.add(l10n.shareContactLine(business.whatsappPhone!));
  }
  return lines.join('\n').trim();
}

/// Asks how to share (rate, watermark), prepares the photos and opens the
/// share sheet. Safe to call from any screen.
Future<void> shareDesigns(
  BuildContext context,
  ProductSharer sharer,
  List<String> productIds, {
  String? customerId,
}) async {
  if (productIds.isEmpty) return;
  final l10n = AppLocalizations.of(context);
  final options = await showModalBottomSheet<ShareOptions>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ShareOptionsSheet(count: productIds.length, customerId: customerId),
  );
  if (options == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(minutes: 1),
      content: Row(
        children: [
          const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.sharePreparing(productIds.length)),
        ],
      ),
    ),
  );
  try {
    final outcome = await sharer.share(productIds, options, (products, o) => buildShareCaption(l10n, products, o));
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    switch (outcome) {
      case ShareOutcome.unavailable:
        AppFeedback.show(context, l10n.shareFailed, tone: FeedbackTone.error);
      case ShareOutcome.sharedTextOnly:
        AppFeedback.show(context, l10n.shareNoPhotos, tone: FeedbackTone.info);
      case ShareOutcome.shared:
        break;
    }
  } on Object catch (error) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) {
      AppFeedback.show(context, AppFailure.from(error).message(l10n), tone: FeedbackTone.error);
    }
  }
}

class _ShareOptionsSheet extends StatefulWidget {
  const _ShareOptionsSheet({required this.count, this.customerId});

  final int count;
  final String? customerId;

  @override
  State<_ShareOptionsSheet> createState() => _ShareOptionsSheetState();
}

class _ShareOptionsSheetState extends State<_ShareOptionsSheet> {
  bool _showRate = true;
  bool _watermark = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.shareDesignsTitle, style: text.titleLarge),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shareShowRate),
              value: _showRate,
              onChanged: (v) => setState(() => _showRate = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shareAddWatermark),
              value: _watermark,
              onChanged: (v) => setState(() => _watermark = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.commonShare,
              icon: Icons.share_rounded,
              onPressed: () =>
                  Navigator.of(context)
                      .pop(ShareOptions(showRate: _showRate, watermark: _watermark, customerId: widget.customerId)),
            ),
          ],
        ),
      ),
    );
  }
}
