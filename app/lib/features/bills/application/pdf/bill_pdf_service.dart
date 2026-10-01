import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../domain/bills.dart';
import 'bill_pdf_layout.dart';
import 'bill_pdf_renderer.dart';
import 'pdf_image_embedding_service.dart';

typedef BillPdfRenderer = Future<Uint8List> Function(BillPdfInput input);
typedef BillFonts = Future<({Uint8List regular, Uint8List bold})> Function();

/// Typesetting runs in a background isolate.
final billPdfRendererProvider = Provider<BillPdfRenderer>(
  (ref) =>
      (input) => compute(renderBillPdf, input),
);

/// Hind covers Latin, digits and ₹ (subset-embedded: only used glyphs).
final billFontsProvider = Provider<BillFonts>(
  (ref) =>
      () async => (
        regular: (await rootBundle.load('assets/fonts/Hind-Regular.ttf')).buffer.asUint8List(),
        bold: (await rootBundle.load('assets/fonts/Hind-SemiBold.ttf')).buffer.asUint8List(),
      ),
);

final billPdfServiceProvider = Provider<BillPdfService>(
  (ref) => BillPdfService(
    images: PdfImageEmbeddingService(ref.watch(optimizedImageLoaderProvider)),
    shaper: ref.watch(textRasterizerProvider),
    fonts: ref.watch(billFontsProvider),
    renderer: ref.watch(billPdfRendererProvider),
  ),
);

@immutable
class BillPdf {
  const BillPdf({required this.bytes, required this.photos, required this.placeholders});

  final Uint8List bytes;

  /// Distinct photos embedded.
  final int photos;

  /// Lines drawn with a placeholder (no photo stored, or it could not be loaded).
  final int placeholders;
}

/// Builds the bill PDF: photos (fetched, optimised, cached, de-duplicated)
/// → Indic text shaped by Flutter → typeset off the UI isolate. A photo
/// that cannot be loaded never fails the bill.
class BillPdfService {
  const BillPdfService({required this._images, required this._shaper, required this._fonts, required this._renderer});

  final PdfImageEmbeddingService _images;
  final TextRasterizer _shaper;
  final BillFonts _fonts;
  final BillPdfRenderer _renderer;

  Future<BillPdf> generate(BillDocument bill, BillPdfLabels labels) async {
    final tier = BillImageTier.forCount(bill.items.length);
    final layout = BillPdfLayout(tier);
    final photos = await _images.prepare(bill.items, tier);

    final shaped = <String, RasterText>{};
    for (final (style, text, maxWidth) in billTextRuns(bill, labels, layout)) {
      final key = style.key(text);
      if (!needsShaping(text) || shaped.containsKey(key)) continue;
      shaped[key] = await _shaper(text, fontSize: style.size, bold: style.bold, maxWidth: maxWidth);
    }

    final fonts = await _fonts();
    final bytes = await _renderer(
      BillPdfInput(
        bill: bill,
        labels: labels,
        tier: tier,
        images: photos,
        shapedText: shaped,
        regularFont: fonts.regular,
        boldFont: fonts.bold,
      ),
    );
    final placeholders = bill.items.where((i) => i.imagePath == null || !photos.containsKey(i.imagePath)).length;
    return BillPdf(bytes: bytes, photos: photos.length, placeholders: placeholders);
  }
}
