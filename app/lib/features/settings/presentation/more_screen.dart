import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/locale_controller.dart';
import 'legal_screen.dart';

/// More: who I am, language, legal, logout. Owner settings sections grow here
/// in later increments via progressive disclosure — not a 40-item menu.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key, required this.onOpenLegal});

  final ValueChanged<LegalDocument> onOpenLegal;

  static const _languageNames = {'gu': 'ગુજરાતી', 'hi': 'हिन्दी', 'en': 'English'};

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
              child: Text(l10n.moreLanguage, style: Theme.of(context).textTheme.titleLarge),
            ),
            RadioGroup<String>(
              groupValue: current.languageCode,
              onChanged: (code) => Navigator.of(context).pop(Locale(code!)),
              child: Column(
                children: [
                  for (final locale in supportedAppLocales)
                    RadioListTile<String>(
                      value: locale.languageCode,
                      title: Text(_languageNames[locale.languageCode]!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (picked != null) await ref.read(localeControllerProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final session = ref.watch(currentSessionProvider);
    final config = ref.watch(appConfigProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            children: [
              if (session != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.xs),
                  child: AppCard(
                    child: Row(
                      children: [
                        const BrandMark(size: 44),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.displayName,
                                style: text.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                session.businessName,
                                style: text.bodyMedium!.copyWith(color: AppColors.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: session.isOwner ? l10n.roleOwner : l10n.roleStaff,
                          tone: session.isOwner ? StatusTone.accent : StatusTone.neutral,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(l10n.moreLanguage),
                subtitle: Text(_languageNames[languageCode] ?? languageCode),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickLanguage(context, ref),
              ),
              const Divider(indent: AppSpacing.gutter, endIndent: AppSpacing.gutter),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.morePrivacy),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpenLegal(LegalDocument.privacy),
              ),
              ListTile(
                leading: const Icon(Icons.gavel_rounded),
                title: Text(l10n.moreTerms),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpenLegal(LegalDocument.terms),
              ),
              const Divider(indent: AppSpacing.gutter, endIndent: AppSpacing.gutter),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(l10n.moreLogout, style: text.titleMedium!.copyWith(color: AppColors.error)),
                onTap: () => ref.read(sessionControllerProvider.notifier).signOut(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(child: Text('${l10n.appName} · ${l10n.appVersion(config.appVersion)}', style: text.bodySmall)),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
