import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/bill_providers.dart';

/// Bill block on the order screen (composed in by the app layer).
class BillSection extends ConsumerWidget {
  const BillSection({super.key, required this.orderId, this.billId, this.billNo});

  final String orderId;
  final String? billId;
  final int? billNo;

  Future<void> _make(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      final bill = await ref.read(billIssuerProvider).issue(orderId);
      ref.read(appNavigatorProvider).openBill(bill.billId);
    } on AppFailure catch (f) {
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        f.code == 'order_cancelled' ? l10n.billCancelledOrder : f.message(l10n),
        tone: FeedbackTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final canIssue = ref.watch(currentSessionProvider)?.can(Permission.billsIssue) ?? false;
    if (billId != null) {
      return AppCard(
        onTap: () => ref.read(appNavigatorProvider).openBill(billId!),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.goldText),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.billNumber('$billNo'), style: text.titleMedium)),
            Text(l10n.billView, style: text.labelLarge!.copyWith(color: AppColors.goldText)),
          ],
        ),
      );
    }
    if (!canIssue) return const SizedBox.shrink();
    return AppButton(
      label: l10n.billMake,
      icon: Icons.description_outlined,
      variant: AppButtonVariant.secondary,
      onPressed: () => _make(context, ref),
    );
  }
}
