import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/customer_providers.dart';
import '../domain/customers.dart';

/// Per-customer selling rates. Everyone taking orders can see them (they
/// are the rates that will be charged); changing them needs rates.manage.
class CustomerRatesScreen extends ConsumerWidget {
  const CustomerRatesScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _edit(BuildContext context, WidgetRef ref, {CustomerRate? existing}) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<({String designNo, Money rate})>(
      context: context,
      builder: (_) => _RateDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    final editor = ref.read(customerEditorProvider);
    try {
      var productId = existing?.productId;
      if (productId == null) {
        final found = await editor.findDesign(customerId, result.designNo);
        if (found == null) {
          if (context.mounted) AppFeedback.show(context, l10n.designNotFound, tone: FeedbackTone.error);
          return;
        }
        productId = found.productId;
      }
      await editor.setRate(customerId, productId, result.rate);
      if (context.mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, CustomerRate rate) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(customerEditorProvider).removeRate(customerId, rate.productId);
    } on AppFailure catch (f) {
      if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final canEdit = ref.watch(currentSessionProvider)?.can(Permission.ratesManage) ?? false;
    final rates = ref.watch(customerRatesProvider(customerId));
    final name = ref.watch(customerDetailProvider(customerId)).value?.name;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.specialRatesTitle),
            if (name != null) Text(name, style: text.bodySmall!.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.specialRateAdd),
            )
          : null,
      body: switch (rates) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          icon: Icons.sell_outlined,
          title: l10n.specialRatesEmpty,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.only(bottom: AppSpacing.huge * 2),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = value[i];
            return ListTile(
              title: Text('${r.designNo} · ${r.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(l10n.specialRateNormal(r.defaultRate.format())),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoneyText(r.rate, style: text.titleMedium),
                  if (canEdit)
                    IconButton(
                      tooltip: l10n.specialRateRemove,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _remove(context, ref, r),
                    ),
                ],
              ),
              onTap: canEdit ? () => _edit(context, ref, existing: r) : null,
            );
          },
        ),
        AsyncError(:final error) => ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.refresh(customerRatesProvider(customerId).future),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _RateDialog extends StatefulWidget {
  const _RateDialog({this.existing});

  final CustomerRate? existing;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  final _form = GlobalKey<FormState>();
  late final _design = TextEditingController(text: widget.existing?.designNo ?? '');
  late final _rate = TextEditingController(text: widget.existing?.rate.format(symbol: false).replaceAll(',', '') ?? '');

  @override
  void dispose() {
    _design.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.specialRateAdd : widget.existing!.designNo),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.existing == null)
              TextFormField(
                controller: _design,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.fieldDesignNo),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
              ),
            TextFormField(
              controller: _rate,
              autofocus: widget.existing != null,
              decoration: InputDecoration(labelText: l10n.fieldRate, prefixText: '₹ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              validator: (v) => (Money.tryParseRupees(v ?? '')?.paise ?? 0) > 0 ? null : l10n.validationAmount,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop((designNo: _design.text.trim(), rate: Money.tryParseRupees(_rate.text)!));
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
