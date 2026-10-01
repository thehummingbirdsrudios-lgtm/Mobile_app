import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/bill_providers.dart';
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

  Future<void> _share(BillDocument bill, {required bool pdf}) async {
    final l10n = AppLocalizations.of(context);
    try {
      final photo = await _photo(bill);
      final file = pdf
          ? ShareFile(
              bytes: await ref.read(pdfBuilderProvider)(
                ImagePdfInput(png: photo.bytes, title: l10n.billNumber('${bill.billNo}')),
              ),
              name: '${photo.name}.pdf',
              mimeType: 'application/pdf',
            )
          : ShareFile(bytes: photo.bytes, name: '${photo.name}.png', mimeType: 'image/png');
      final ok = await ref
          .read(fileSharerProvider)
          .share(files: [file], text: l10n.billShareText('${bill.billNo}', bill.business.name));
      if (!ok && mounted) AppFeedback.show(context, l10n.shareFailed, tone: FeedbackTone.error);
    } on Object {
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
                    onPressed: () => _share(value, pdf: false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: l10n.billSharePdf,
                    icon: Icons.picture_as_pdf_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _share(value, pdf: true),
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
