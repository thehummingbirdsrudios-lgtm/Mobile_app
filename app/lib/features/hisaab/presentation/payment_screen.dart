import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/customers.dart';
import '../application/hisaab_providers.dart';
import 'ledger_screen.dart' show bakiText;

/// Record money received. Shows the Baki after this payment before saving;
/// the server computes the real figure and prints it on the receipt.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  // One id per form: a retried save never records the payment twice.
  final _requestId = newUuid();
  PaymentMode _mode = PaymentMode.cash;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_form.currentState?.validate() ?? false)) return;
    final nav = ref.read(appNavigatorProvider);
    try {
      final recorded = await ref
          .read(hisaabWriterProvider)
          .recordPayment(
            customerId: widget.customerId,
            amount: Money.tryParseRupees(_amount.text)!,
            mode: _mode,
            requestId: _requestId,
            reference: _reference.text,
            note: _note.text,
          );
      if (!mounted) return;
      AppFeedback.show(context, recorded.replayed ? l10n.paymentAlreadySaved : l10n.commonSaved);
      nav
        ..back()
        ..openReceipt(recorded.paymentId);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final customer = ref.watch(customerDetailProvider(widget.customerId)).value;
    final baki = customer?.baki;
    final amount = Money.tryParseRupees(_amount.text);
    final after = baki == null || amount == null ? null : baki - amount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.paymentRecord),
            if (customer != null) Text(customer.name, style: text.bodySmall!.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
      body: Form(
        key: _form,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
            // Not a lazy ListView: every field must stay mounted so Form.validate()
            // also checks fields scrolled off-screen.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amount,
                    autofocus: true,
                    style: text.headlineMedium!.copyWith(fontFeatures: AppType.figures),
                    decoration: InputDecoration(labelText: l10n.fieldAmount, prefixText: '₹ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    validator: (v) => (Money.tryParseRupees(v ?? '')?.paise ?? 0) > 0 ? null : l10n.validationAmount,
                  ),
                  if (baki != null && baki.paise > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        label: Text(l10n.paymentFullBaki(baki.format())),
                        onPressed: () => _amount.text = baki.format(symbol: false).replaceAll(',', ''),
                      ),
                    ),
                  ],
                  if (after != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      after.isNegative
                          ? l10n.paymentAdvanceAfter((-after).format())
                          : l10n.paymentBakiAfter(after.format()),
                      style: text.bodyLarge!.copyWith(color: AppColors.muted, fontFeatures: AppType.figures),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.fieldPaymentMode, style: text.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final m in PaymentMode.values)
                        ChoiceChip(
                          label: Text(paymentModeLabel(l10n, m)),
                          selected: _mode == m,
                          onSelected: (_) => setState(() => _mode = m),
                        ),
                    ],
                  ),
                  if (_mode != PaymentMode.cash) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _reference,
                      maxLength: 60,
                      decoration: InputDecoration(labelText: l10n.fieldReference),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _note,
                    maxLength: 400,
                    decoration: InputDecoration(labelText: l10n.fieldNotes),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(label: l10n.paymentSave, icon: Icons.check_rounded, onPressed: _save),
                  if (baki != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${l10n.bakiLabel}: ${bakiText(l10n, baki)}',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium!.copyWith(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
