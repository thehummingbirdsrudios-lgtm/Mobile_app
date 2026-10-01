import '../../../../core/media/remote_images/image_models.dart';

/// Photo size by number of lines. Every line always shows its photo; larger
/// bills use a smaller cell and a smaller (but still ~5 px/pt, ≈ 360 dpi)
/// image, so photos stay sharp when zoomed or printed while the PDF stays
/// small enough for WhatsApp.
enum BillImageTier {
  /// 1–15 lines.
  standard(boxPt: 64, spec: ImageSpec(maxEdgePx: 360, jpegQuality: 88)),

  /// 16–20 lines.
  compact(boxPt: 56, spec: ImageSpec(maxEdgePx: 300, jpegQuality: 86)),

  /// 21+ lines.
  dense(boxPt: 48, spec: ImageSpec(maxEdgePx: 240, jpegQuality: 85));

  const BillImageTier({required this.boxPt, required this.spec});

  final double boxPt;
  final ImageSpec spec;

  static BillImageTier forCount(int lines) => lines <= 15
      ? standard
      : lines <= 20
      ? compact
      : dense;
}

/// Column geometry shared by the typesetter and the text shaper (shaped
/// text is wrapped to the same widths it is drawn in).
class BillPdfLayout {
  const BillPdfLayout(this.tier);

  final BillImageTier tier;

  static const pageMargin = 28.0;
  static const contentWidth = 595.28 - pageMargin * 2; // A4 portrait
  static const cellPadding = 4.0;
  static const designWidth = 66.0;
  static const qtyWidth = 38.0;
  static const rateWidth = 64.0;
  static const amountWidth = 74.0;

  double get imageWidth => tier.boxPt + cellPadding * 2;
  double get itemWidth => contentWidth - imageWidth - designWidth - qtyWidth - rateWidth - amountWidth;

  /// Usable text width inside the item column.
  double get itemTextWidth => itemWidth - cellPadding * 2;
}

/// Text styles of the bill (points).
enum BillText {
  title(15, bold: true),
  heading(10.5, bold: true),
  body(9),
  bodyBold(9, bold: true),
  small(7.5),
  label(7.5, bold: true);

  const BillText(this.size, {this.bold = false});

  final double size;
  final bool bold;

  String key(String text) => '$name|$text';
}
