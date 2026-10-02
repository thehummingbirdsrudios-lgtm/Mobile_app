import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/export_service.dart';
import '../domain/export.dart';

/// Owner export: pick what and when, get a CSV through the share sheet.
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(currentSessionProvider.select((s) => s?.isOwner ?? false));
    if (isOwner) return const _ExportForm();
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(icon: Icons.lock_outline_rounded, title: AppLocalizations.of(context).adminOwnerOnly),
    );
  }
}

String exportKindLabel(AppLocalizations l10n, ExportKind k) => switch (k) {
  ExportKind.customers => l10n.exportKindCustomers,
  ExportKind.designs => l10n.exportKindDesigns,
  ExportKind.ledger => l10n.exportKindLedger,
  ExportKind.orders => l10n.exportKindOrders,
  ExportKind.orderLines => l10n.exportKindOrderLines,
};

String exportColumnLabel(AppLocalizations l10n, ExportColumn c) => switch (c) {
  ExportColumn.customer => l10n.colCustomer,
  ExportColumn.shopName => l10n.colShop,
  ExportColumn.city => l10n.colCity,
  ExportColumn.phone => l10n.colPhone,
  ExportColumn.whatsapp => l10n.colWhatsapp,
  ExportColumn.baki => l10n.colBaki,
  ExportColumn.archived => l10n.colArchived,
  ExportColumn.createdAt => l10n.colCreatedAt,
  ExportColumn.designNo => l10n.colDesignNo,
  ExportColumn.productName => l10n.colProduct,
  ExportColumn.category => l10n.colCategory,
  ExportColumn.rate => l10n.colRate,
  ExportColumn.weight => l10n.colWeight,
  ExportColumn.available => l10n.colAvailable,
  ExportColumn.publishedAt => l10n.colPublishedAt,
  ExportColumn.cost => l10n.colCost,
  ExportColumn.supplier => l10n.colSupplier,
  ExportColumn.date => l10n.colDate,
  ExportColumn.entryKind => l10n.colEntryKind,
  ExportColumn.amount => l10n.colAmount,
  ExportColumn.balanceAfter => l10n.colBalanceAfter,
  ExportColumn.orderNo => l10n.colOrderNo,
  ExportColumn.paymentMode => l10n.colPaymentMode,
  ExportColumn.reference => l10n.colReference,
  ExportColumn.note => l10n.colNote,
  ExportColumn.status => l10n.colStatus,
  ExportColumn.totalQty => l10n.colTotalQty,
  ExportColumn.total => l10n.colTotal,
  ExportColumn.lineNo => l10n.colLineNo,
  ExportColumn.qty => l10n.colQty,
};

/// Server codes written in the user's language.
Map<String, String> exportCodeLabels(AppLocalizations l10n) => {
  'confirmed': l10n.statusConfirmed,
  'processing': l10n.statusProcessing,
  'ready': l10n.statusReady,
  'completed': l10n.statusCompleted,
  'cancelled': l10n.statusCancelled,
  'opening': l10n.ledgerOpening,
  'order': l10n.exportEntryOrder,
  'payment': l10n.exportEntryPayment,
  'adjustment': l10n.ledgerAdjustment,
  'reversal': l10n.ledgerReversalPlain,
  for (final m in PaymentMode.values) m.name: paymentModeLabel(l10n, m),
};

class _ExportForm extends ConsumerStatefulWidget {
  const _ExportForm();

  @override
  ConsumerState<_ExportForm> createState() => _ExportFormState();
}

class _ExportFormState extends ConsumerState<_ExportForm> {
  ExportKind _kind = ExportKind.customers;
  ExportPeriod? _period = ExportPeriod.thisMonth;
  ExportRange? _custom;
  int? _progress;

  ExportRange? get _range => _period?.rangeAt(DateTime.now()) ?? _custom;

  String _periodLabel(AppLocalizations l10n, ExportPeriod p) => switch (p) {
    ExportPeriod.thisMonth => l10n.exportPeriodThisMonth,
    ExportPeriod.lastMonth => l10n.exportPeriodLastMonth,
    ExportPeriod.last3Months => l10n.exportPeriodLast3Months,
    ExportPeriod.thisYear => l10n.exportPeriodThisYear,
  };

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _custom == null
          ? null
          : DateTimeRange(start: _custom!.from, end: _custom!.to.subtract(const Duration(days: 1))),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = null;
      // Whole days: the end date is included.
      _custom = (from: picked.start, to: DateTime(picked.end.year, picked.end.month, picked.end.day + 1));
    });
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final sharer = ref.read(fileSharerProvider);
    setState(() => _progress = 0);
    try {
      final result = await ref
          .read(exportServiceProvider)
          .build(
            _kind,
            range: _kind.isDated ? _range : null,
            header: [for (final c in _kind.columns) exportColumnLabel(l10n, c)],
            yes: l10n.exportYes,
            no: l10n.exportNo,
            labels: exportCodeLabels(l10n),
            onProgress: (n) {
              if (mounted) setState(() => _progress = n);
            },
          );
      if (!mounted) return;
      if (result.rows == 0) {
        AppFeedback.show(context, l10n.exportDone(0), tone: FeedbackTone.info);
        return;
      }
      final shared = await sharer.share(files: [result.file]);
      if (!mounted) return;
      AppFeedback.show(
        context,
        shared ? l10n.exportDone(result.rows) : l10n.exportShareFailed,
        tone: shared ? FeedbackTone.success : FeedbackTone.error,
      );
    } on AppFailure catch (f) {
      if (!mounted) return;
      AppFeedback.show(
        context,
        f.code == 'export_too_large' ? l10n.exportTooLarge : f.message(l10n),
        tone: FeedbackTone.error,
      );
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final busy = _progress != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminExport)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: Text(l10n.exportWhat, style: text.titleMedium),
              ),
              RadioGroup<ExportKind>(
                groupValue: _kind,
                onChanged: (k) {
                  if (!busy && k != null) setState(() => _kind = k);
                },
                child: Column(
                  children: [
                    for (final k in ExportKind.values)
                      RadioListTile<ExportKind>(value: k, title: Text(exportKindLabel(l10n, k))),
                  ],
                ),
              ),
              if (_kind == ExportKind.designs)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(l10n.exportCostWarning, style: text.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              if (_kind.isDated) ...[
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Text(l10n.exportPeriod, style: text.titleMedium),
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final p in ExportPeriod.values)
                        ChoiceChip(
                          label: Text(_periodLabel(l10n, p)),
                          selected: _period == p,
                          onSelected: busy ? null : (_) => setState(() => _period = p),
                        ),
                      ChoiceChip(
                        label: Text(
                          _custom == null
                              ? l10n.exportPeriodCustom
                              : l10n.exportPeriodRange(
                                  AppFormat.fullDate(_custom!.from, locale),
                                  AppFormat.fullDate(_custom!.to.subtract(const Duration(days: 1)), locale),
                                ),
                        ),
                        selected: _period == null,
                        onSelected: busy ? null : (_) => unawaited(_pickDates()),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: AppButton(
                  label: l10n.exportButton,
                  icon: Icons.ios_share_rounded,
                  onPressed: busy || (_kind.isDated && _range == null) ? null : _export,
                ),
              ),
              if (busy)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Text(
                    l10n.exportReading(AppFormat.count(_progress!)),
                    style: text.bodyMedium!.copyWith(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}
