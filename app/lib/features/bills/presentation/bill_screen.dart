import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/bill_providers.dart';
import '../application/pdf/bill_pdf_renderer.dart' show BillPdfLabels;
import '../application/pdf/bill_pdf_service.dart';
import '../domain/bills.dart';
import 'bill_view.dart';

/// Shows the bill and sends it as a photo (best for WhatsApp) or a PDF.
class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key, required this.billId});

  final String billId;

  /// The bill is always laid out at this width and scaled to the screen, so
  /// every phone shares the same image.
  static const layoutWidth = 400.0;

  /// Width of the shared image in pixels (readable on any phone).
  static const imageWidthPx = 1240.0;

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
  final _boundary = GlobalKey();

  Future<_Photo> _photo(BillDocument bill) async {
    const ratio = BillScreen.imageWidthPx / BillScreen.layoutWidth;
    final png = await ref.read(widgetCapturerProvider)(_boundary, pixelRatio: ratio);
    return (bytes: png, name: 'bill-${bill.billNo}');
  }

  Future<void> _sharePhoto(BillDocument bill) async {
    final l10n = AppLocalizations.of(context);
    try {
      final photo = await _photo(bill);
      final ok = await ref
          .read(fileSharerProvider)
          .share(
            files: [ShareFile(bytes: photo.bytes, name: '${photo.name}.png', mimeType: 'image/png')],
            text: l10n.billShareText('${bill.billNo}', bill.business.name),
          );
      if (!ok && mounted) AppFeedback.show(context, l10n.shareFailed, tone: FeedbackTone.error);
    } on Object {
      if (mounted) AppFeedback.show(context, l10n.shareFailed, tone: FeedbackTone.error);
    }
  }

  BillPdfLabels _labels(BillDocument bill) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return BillPdfLabels(
      title: l10n.billTitle,
      billNo: l10n.billNumber('${bill.billNo}'),
      date: AppFormat.fullDate(bill.issuedAt, locale),
      orderRef: l10n.billOrderRef('${bill.orderNo}'),
      billTo: l10n.billTo,
      colPhoto: l10n.billColPhoto,
      colDesign: l10n.billColDesign,
      colItem: l10n.billColItem,
      colQty: l10n.billColQty,
      colRate: l10n.billColRate,
      colAmount: l10n.billColAmount,
      totalQty: l10n.billColQty,
      totalWeight: l10n.billWeight,
      total: l10n.billTotal,
      paid: l10n.billPaid,
      bakiAfter: l10n.billBakiAfter,
      advance: l10n.advanceLabel,
      continued: l10n.billContinued,
    );
  }

  /// The real bill PDF: every line with its product photo (fetched,
  /// optimised, cached), paginated, typeset off the UI thread.
  Future<void> _sharePdf(BillDocument bill) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 2),
        content: Row(
          children: [
            const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.billPdfPreparing(bill.items.where((i) => i.imagePath != null).length))),
          ],
        ),
      ),
    );
    try {
      final pdf = await ref.read(billPdfServiceProvider).generate(bill, _labels(bill));
      messenger.hideCurrentSnackBar();
      final ok = await ref
          .read(fileSharerProvider)
          .share(
            files: [ShareFile(bytes: pdf.bytes, name: 'bill-${bill.billNo}.pdf', mimeType: 'application/pdf')],
            text: l10n.billShareText('${bill.billNo}', bill.business.name),
          );
      if (!ok && mounted) AppFeedback.show(context, l10n.shareFailed, tone: FeedbackTone.error);
    } on Object {
      messenger.hideCurrentSnackBar();
      if (mounted) AppFeedback.show(context, l10n.shareFailed, tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(billDocumentProvider(widget.billId))) {
      AsyncData(:final value?) => Scaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(title: Text(l10n.billNumber('${value.billNo}'))),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.billSendPhoto,
                    icon: Icons.image_outlined,
                    onPressed: () => _sharePhoto(value),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: l10n.billSharePdf,
                    icon: Icons.picture_as_pdf_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _sharePdf(value),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: BillScreen.layoutWidth,
                  child: RepaintBoundary(
                    key: _boundary,
                    child: BillView(bill: value),
                  ),
                ),
              ),
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
          onRetry: () => ref.refresh(billDocumentProvider(widget.billId).future),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.billPreparing)),
      ),
    };
  }
}

typedef _Photo = ({Uint8List bytes, String name});
