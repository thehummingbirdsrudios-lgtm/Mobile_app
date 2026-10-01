import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/hisaab_providers.dart';
import '../domain/hisaab.dart';
import 'ledger_screen.dart' show bakiText;

/// Optional extras supplied by other modules (e.g. send as an image/PDF).
class ReceiptActions {
  const ReceiptActions({this.onShareFile});

  final Future<void> Function(PaymentReceipt receipt)? onShareFile;
}

final receiptActionsProvider = Provider<ReceiptActions>((ref) => const ReceiptActions());

/// Payment receipt from `payment_receipt` (share-safe fields only).
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.paymentId});

  final String paymentId;

  Future<void> _send(BuildContext context, WidgetRef ref, PaymentReceipt r) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final message = l10n.receiptMessage(
      r.amount.format(),
      paymentModeLabel(l10n, r.mode),
      AppFormat.fullDate(r.receivedAt, locale),
      '${r.paymentNo}',
      bakiText(l10n, r.balanceAfter),
      r.businessName,
    );
    final ok = await ref.read(contactLauncherProvider).whatsapp(r.customerPhone!, text: message);
    if (!ok && context.mounted) AppFeedback.show(context, l10n.whatsappUnavailable, tone: FeedbackTone.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final receipt = ref.watch(paymentReceiptProvider(paymentId));
    final actions = ref.watch(receiptActionsProvider);
    return switch (receipt) {
      AsyncData(:final value?) => Scaffold(
        appBar: AppBar(title: Text(l10n.receiptTitle('${value.paymentNo}'))),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: [
                ReceiptCard(receipt: value),
                const SizedBox(height: AppSpacing.lg),
                if (value.customerPhone != null)
                  AppButton(
                    label: l10n.receiptSend,
                    icon: Icons.chat_outlined,
                    onPressed: () => _send(context, ref, value),
                  ),
                if (actions.onShareFile != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.commonShare,
                    icon: Icons.share_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => actions.onShareFile!(value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off_rounded, title: l10n.commonNotFound),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.refresh(paymentReceiptProvider(paymentId).future),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// The receipt as printed: business, customer, amount, mode, Baki.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt});

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final r = receipt;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyLarge!.copyWith(fontFeatures: AppType.figures),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.businessName, style: text.titleLarge, textAlign: TextAlign.center),
          if (r.businessAddress != null)
            Text(
              r.businessAddress!,
              style: text.bodySmall!.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          if (r.businessPhone != null || r.gstin != null)
            Text(
              [?r.businessPhone, if (r.gstin != null) 'GSTIN ${r.gstin}'].join(' · '),
              style: text.bodySmall!.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          const Divider(height: AppSpacing.xl),
          Text(l10n.receiptTitle('${r.paymentNo}'), style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: MoneyText(r.amount, style: text.displaySmall!.copyWith(color: AppColors.success)),
          ),
          const SizedBox(height: AppSpacing.md),
          row(l10n.receiptReceivedFrom, r.customerName),
          row(l10n.receiptMode, paymentModeLabel(l10n, r.mode)),
          if (r.reference != null) row(l10n.receiptReference, r.reference!),
          row(l10n.receiptDate, AppFormat.dateTime(r.receivedAt, locale)),
          const Divider(height: AppSpacing.lg),
          row(l10n.receiptBakiBefore, bakiText(l10n, r.balanceBefore)),
          row(l10n.receiptBakiNow, bakiText(l10n, r.balanceAfter)),
        ],
      ),
    );
  }
}
