import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../../customers/customers.dart';
import '../application/hisaab_providers.dart';
import '../domain/hisaab.dart';

/// "Baki" for display: owed amounts as Baki, overpayments as Advance.
String bakiText(AppLocalizations l10n, Money balance) =>
    balance.isNegative ? '${l10n.advanceLabel} ${(-balance).format()}' : balance.format();

/// One customer's Hisaab: current Baki, then every entry with the running
/// balance. Corrections are new entries; nothing is ever edited.
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _sendHisaab(BuildContext context, WidgetRef ref, CustomerDetail c) async {
    final l10n = AppLocalizations.of(context);
    final business = ref.read(currentSessionProvider)?.businessName ?? '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = l10n.hisaabMessage(
      c.name,
      business,
      bakiText(l10n, c.baki ?? Money.zero),
      AppFormat.fullDate(DateTime.now(), locale),
    );
    final ok = await ref.read(contactLauncherProvider).whatsapp(c.whatsappNumber!, text: text);
    if (!ok && context.mounted) AppFeedback.show(context, l10n.whatsappUnavailable, tone: FeedbackTone.error);
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref, {required bool opening}) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<({Money amount, String note})>(
      context: context,
      builder: (_) => _AdjustDialog(opening: opening),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(hisaabWriterProvider)
          .recordAdjustment(
            customerId: customerId,
            amount: result.amount,
            note: result.note,
            opening: opening,
            requestId: newUuid(),
          );
      if (context.mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        f.code == 'opening_exists' ? l10n.openingAlreadySet : f.message(l10n),
        tone: FeedbackTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final nav = ref.watch(appNavigatorProvider);
    final session = ref.watch(currentSessionProvider);
    bool can(Permission p) => session?.can(p) ?? false;
    final customer = ref.watch(customerDetailProvider(customerId)).value;
    final ledger = ref.watch(ledgerProvider(customerId));
    final notifier = ref.read(ledgerProvider(customerId).notifier);

    if (!can(Permission.hisaabView)) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.lock_outline_rounded, title: l10n.hisaabNoPermission),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(customer?.name ?? l10n.navHisaab, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (customer?.whatsappNumber != null)
            IconButton(
              tooltip: l10n.hisaabSend,
              icon: const Icon(Icons.chat_outlined),
              onPressed: () => _sendHisaab(context, ref, customer!),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: RefreshIndicator(
            color: AppColors.ink,
            onRefresh: notifier.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.bakiLabel, style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                        Text(
                          customer?.baki == null ? '—' : bakiText(l10n, customer!.baki!),
                          style: text.displaySmall!.copyWith(fontFeatures: AppType.figures),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            if (can(Permission.paymentsRecord) && customer?.isArchived != true)
                              Expanded(
                                child: AppButton(
                                  label: l10n.actionPayment,
                                  icon: Icons.currency_rupee_rounded,
                                  onPressed: () => nav.openPayment(customerId),
                                ),
                              ),
                            if (can(Permission.hisaabAdjust)) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppButton(
                                  label: l10n.adjustAction,
                                  icon: Icons.tune_rounded,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: () => unawaited(_adjust(context, ref, opening: false)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (can(Permission.hisaabAdjust) && ledger.items.isEmpty && !ledger.isLoadingFirst)
                          TextButton(
                            onPressed: () => unawaited(_adjust(context, ref, opening: true)),
                            child: Text(l10n.openingSet),
                          ),
                      ],
                    ),
                  ),
                ),
                PagedSliverBody<LedgerEntry, LedgerCursor>(
                  state: ledger,
                  padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                  onLoadMore: notifier.loadMore,
                  onRetry: notifier.retry,
                  itemBuilder: (context, e) => _EntryTile(
                    entry: e,
                    onTap: switch (e) {
                      LedgerEntry(paymentId: final id?) => () => nav.openReceipt(id),
                      LedgerEntry(orderId: final id?) => () => nav.openOrder(id),
                      _ => null,
                    },
                  ),
                  skeleton: const Center(
                    child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
                  ),
                  empty: EmptyState(icon: Icons.menu_book_outlined, title: l10n.ledgerEmpty),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, this.onTap});

  final LedgerEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final e = entry;
    final (icon, title) = switch (e.kind) {
      LedgerKind.opening => (Icons.flag_outlined, l10n.ledgerOpening),
      LedgerKind.order => (Icons.receipt_long_outlined, l10n.ledgerOrder('${e.orderNo ?? ''}')),
      LedgerKind.payment => (
        Icons.currency_rupee_rounded,
        l10n.ledgerPayment(e.paymentMode == null ? '' : paymentModeLabel(l10n, e.paymentMode!)),
      ),
      LedgerKind.adjustment => (Icons.tune_rounded, l10n.ledgerAdjustment),
      LedgerKind.reversal => (
        Icons.undo_rounded,
        e.orderNo == null ? l10n.ledgerReversalPlain : l10n.ledgerReversal('${e.orderNo}'),
      ),
    };
    final lowers = e.amount.isNegative;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: lowers ? AppColors.successTint : AppColors.surfaceMuted,
        foregroundColor: lowers ? AppColors.success : AppColors.ink,
        child: Icon(icon, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        [
          AppFormat.shortDate(e.createdAt, locale),
          if (e.kind == LedgerKind.adjustment && (e.note ?? '').isNotEmpty) e.note!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall!.copyWith(color: AppColors.muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${lowers ? '−' : '+'} ${Money.paise(e.amount.paise.abs()).format()}',
            style: text.titleMedium!.copyWith(
              color: lowers ? AppColors.success : AppColors.ink,
              fontFeatures: AppType.figures,
            ),
          ),
          Text(
            e.balanceAfter.isNegative
                ? '${l10n.advanceLabel} ${(-e.balanceAfter).format()}'
                : l10n.balanceAfter(e.balanceAfter.format()),
            style: text.bodySmall!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
          ),
        ],
      ),
    );
  }
}

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.opening});

  final bool opening;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _raise = true;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.opening ? l10n.openingSet : l10n.adjustTitle),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.opening)
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.adjustAdd),
                      selected: _raise,
                      onSelected: (_) => setState(() => _raise = true),
                    ),
                    ChoiceChip(
                      label: Text(l10n.adjustReduce),
                      selected: !_raise,
                      onSelected: (_) => setState(() => _raise = false),
                    ),
                  ],
                ),
              TextFormField(
                controller: _amount,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.fieldAmount, prefixText: '₹ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                validator: (v) => (Money.tryParseRupees(v ?? '')?.paise ?? 0) > 0 ? null : l10n.validationAmount,
              ),
              TextFormField(
                controller: _note,
                maxLength: 400,
                decoration: InputDecoration(labelText: l10n.adjustNoteRequired),
                validator: (v) => !widget.opening && (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            final amount = Money.tryParseRupees(_amount.text)!;
            Navigator.of(context).pop((amount: _raise ? amount : -amount, note: _note.text.trim()));
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
