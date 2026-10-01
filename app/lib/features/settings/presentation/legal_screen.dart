import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/legal_text.dart';

enum LegalDocument {
  privacy('assets/legal/privacy-policy.md'),
  terms('assets/legal/terms-and-conditions.md');

  const LegalDocument(this.asset);

  final String asset;
}

/// Shows a bundled legal document (single source: docs/legal/, synced into
/// assets and checked in CI). Clearly marked as a draft until reviewed.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document, this.bundle});

  final LegalDocument document;
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = document == LegalDocument.privacy ? l10n.morePrivacy : l10n.moreTerms;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: (bundle ?? DefaultAssetBundle.of(context)).loadString(document.asset),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorState(failure: AppFailure.from(snapshot.error!));
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.gutter),
              child: Shimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 220, height: 24),
                    SizedBox(height: AppSpacing.md),
                    SkeletonBox(height: 14),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(height: 14),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: 180, height: 14),
                  ],
                ),
              ),
            );
          }
          final textTheme = Theme.of(context).textTheme;
          final blocks = parseLegalMarkdown(snapshot.data!);
          return SelectionArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: blocks.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(color: AppColors.warningTint, borderRadius: AppRadius.control),
                    child: Text(l10n.legalDraftNotice, style: AppType.label.copyWith(color: AppColors.warning)),
                  );
                }
                return switch (blocks[index - 1]) {
                  LegalHeading(:final text, level: 1) => Text(text, style: textTheme.headlineSmall),
                  LegalHeading(:final text) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(text, style: textTheme.titleLarge),
                  ),
                  LegalNote(:final text) => Text(text, style: textTheme.bodyMedium!.copyWith(color: AppColors.muted)),
                  LegalBullet(:final text) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: textTheme.bodyLarge),
                      Expanded(child: Text(text, style: textTheme.bodyLarge)),
                    ],
                  ),
                  LegalParagraph(:final text) => Text(text, style: textTheme.bodyLarge),
                };
              },
            ),
          );
        },
      ),
    );
  }
}
