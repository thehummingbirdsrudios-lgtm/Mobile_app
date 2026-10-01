import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/format/formatters.dart';
import '../../../../core/media/text_raster.dart';
import '../../../../core/money/money.dart';
import '../../domain/bills.dart';
import 'bill_pdf_layout.dart';

/// Localised, already-formatted words for the bill (plain strings so the
/// whole input can cross into a background isolate).
@immutable
class BillPdfLabels {
  const BillPdfLabels({
    required this.title,
    required this.billNo,
    required this.date,
    required this.orderRef,
    required this.billTo,
    required this.colPhoto,
    required this.colDesign,
    required this.colItem,
    required this.colQty,
    required this.colRate,
    required this.colAmount,
    required this.totalQty,
    required this.totalWeight,
    required this.total,
    required this.paid,
    required this.bakiAfter,
    required this.advance,
    required this.continued,
  });

  final String title;
  final String billNo;
  final String date;
  final String orderRef;
  final String billTo;
  final String colPhoto;
  final String colDesign;
  final String colItem;
  final String colQty;
  final String colRate;
  final String colAmount;
  final String totalQty;
  final String totalWeight;
  final String total;
  final String paid;
  final String bakiAfter;
  final String advance;
  final String continued;
}

/// Everything the typesetter needs; all fields are sendable to an isolate.
@immutable
class BillPdfInput {
  const BillPdfInput({
    required this.bill,
    required this.labels,
    required this.tier,
    required this.images,
    required this.shapedText,
    required this.regularFont,
    required this.boldFont,
  });

  final BillDocument bill;
  final BillPdfLabels labels;
  final BillImageTier tier;

  /// Optimised JPEG per source image key (missing → placeholder).
  final Map<String, Uint8List> images;

  /// Indic text runs pre-shaped by Flutter, keyed by [BillText.key].
  final Map<String, RasterText> shapedText;
  final Uint8List regularFont;
  final Uint8List boldFont;
}

const _ink = PdfColor.fromInt(0xFF1B1A17);
const _muted = PdfColor.fromInt(0xFF6B655C);
const _rule = PdfColor.fromInt(0xFFE7E0D5);
const _headerFill = PdfColor.fromInt(0xFFF3EBDD);
const _stripe = PdfColor.fromInt(0xFFFBF8F3);
const _gold = PdfColor.fromInt(0xFF7A5A1C);

/// Typesets the bill (public for tests; production runs it via `compute`).
/// Rows are atomic (never split across pages), the table header repeats on
/// every page, and each distinct photo is embedded once even if it appears
/// on many rows.
Future<Uint8List> renderBillPdf(BillPdfInput input) {
  final bill = input.bill;
  final l = input.labels;
  final layout = BillPdfLayout(input.tier);
  final regular = pw.Font.ttf(ByteData.sublistView(input.regularFont));
  final bold = pw.Font.ttf(ByteData.sublistView(input.boldFont));
  final photos = {for (final e in input.images.entries) e.key: pw.MemoryImage(e.value)};
  final shaped = {for (final e in input.shapedText.entries) e.key: (e.value, pw.MemoryImage(e.value.png))};

  pw.TextStyle styleOf(BillText t, {PdfColor color = _ink}) =>
      pw.TextStyle(font: t.bold ? bold : regular, fontSize: t.size, color: color, lineSpacing: 1.5);

  /// Vector text, or the Flutter-shaped image of it for Indic scripts.
  pw.Widget text(
    String value,
    BillText t, {
    PdfColor color = _ink,
    pw.TextAlign align = pw.TextAlign.left,
    int maxLines = 2,
  }) {
    final hit = shaped[t.key(value)];
    if (hit != null) {
      final (raster, image) = hit;
      return pw.Image(image, width: raster.width, height: raster.height);
    }
    return pw.Text(
      value,
      style: styleOf(t, color: color),
      textAlign: align,
      maxLines: maxLines,
    );
  }

  pw.Widget cell(pw.Widget child, {pw.Alignment alignment = pw.Alignment.centerLeft}) => pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: BillPdfLayout.cellPadding, vertical: 3),
    child: child,
  );

  pw.Widget photo(String? key) {
    final box = input.tier.boxPt;
    final image = key == null ? null : photos[key];
    return pw.Container(
      width: box,
      height: box,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _rule, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: image == null
          // Placeholder: a small jewel outline, never a broken image.
          ? pw.Transform.rotate(
              angle: math.pi / 4,
              child: pw.Container(
                width: box * 0.22,
                height: box * 0.22,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: _rule, width: 1.2)),
              ),
            )
          : pw.Padding(
              padding: const pw.EdgeInsets.all(1),
              child: pw.Image(image, fit: pw.BoxFit.contain, width: box - 2, height: box - 2),
            ),
    );
  }

  String money(Money m) => m.format();

  final header = pw.TableRow(
    repeat: true,
    decoration: const pw.BoxDecoration(color: _headerFill),
    children: [
      cell(text(l.colPhoto, BillText.label), alignment: pw.Alignment.center),
      cell(text(l.colDesign, BillText.label)),
      cell(text(l.colItem, BillText.label)),
      cell(text(l.colQty, BillText.label), alignment: pw.Alignment.centerRight),
      cell(text(l.colRate, BillText.label), alignment: pw.Alignment.centerRight),
      cell(text(l.colAmount, BillText.label), alignment: pw.Alignment.centerRight),
    ],
  );

  final rows = <pw.TableRow>[
    header,
    for (final (i, item) in bill.items.indexed)
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: pw.BoxDecoration(color: i.isOdd ? _stripe : PdfColors.white),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(BillPdfLayout.cellPadding), child: photo(item.imagePath)),
          cell(text(item.designNo, BillText.bodyBold, maxLines: 2)),
          cell(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                text(item.name, BillText.body),
                if (item.weightMg != null) text(AppFormat.grams(item.weightMg!), BillText.small, color: _muted),
              ],
            ),
          ),
          cell(text('${item.qty}', BillText.body), alignment: pw.Alignment.centerRight),
          cell(text(money(item.rate), BillText.body), alignment: pw.Alignment.centerRight),
          cell(text(money(item.amount), BillText.bodyBold), alignment: pw.Alignment.centerRight),
        ],
      ),
  ];

  pw.Widget totalLine(String label, String value, {bool strong = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.Expanded(child: text(label, strong ? BillText.bodyBold : BillText.body)),
        text(value, strong ? BillText.heading : BillText.body),
      ],
    ),
  );

  final baki = bill.balanceAfter.isNegative ? '${l.advance} ${money(-bill.balanceAfter)}' : money(bill.balanceAfter);

  final b = bill.business;
  final firstHeader = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                text(b.name, BillText.title, maxLines: 2),
                if (b.address != null) text(b.address!, BillText.small, color: _muted),
                if (b.phone != null || b.gstin != null)
                  text(
                    [?b.phone, if (b.gstin != null) 'GSTIN ${b.gstin}'].join('  ·  '),
                    BillText.small,
                    color: _muted,
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              text(l.title, BillText.title, color: _gold),
              text(l.billNo, BillText.bodyBold),
              text(l.date, BillText.small, color: _muted),
              text(l.orderRef, BillText.small, color: _muted),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: _gold, width: 2)),
          color: _stripe,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            text(l.billTo, BillText.small, color: _muted),
            text(bill.customerName, BillText.heading),
            if (bill.customerPhone != null) text(bill.customerPhone!, BillText.small, color: _muted),
          ],
        ),
      ),
      pw.SizedBox(height: 10),
    ],
  );

  final doc = pw.Document(title: l.billNo, author: b.name, creator: 'Vepari', compress: true)
    ..addPage(
      pw.MultiPage(
        maxPages: 200,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: BillPdfLayout.pageMargin,
            marginRight: BillPdfLayout.pageMargin,
            marginTop: BillPdfLayout.pageMargin,
            marginBottom: BillPdfLayout.pageMargin,
          ),
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
        ),
        header: (ctx) => ctx.pageNumber == 1
            ? firstHeader
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(child: text(b.name, BillText.bodyBold, maxLines: 1)),
                    text('${l.billNo} · ${l.continued}', BillText.small, color: _muted),
                  ],
                ),
              ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            children: [
              pw.Expanded(child: text(l.billNo, BillText.small, color: _muted)),
              pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: styleOf(BillText.small, color: _muted)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(layout.imageWidth),
              1: const pw.FixedColumnWidth(BillPdfLayout.designWidth),
              2: pw.FixedColumnWidth(layout.itemWidth),
              3: const pw.FixedColumnWidth(BillPdfLayout.qtyWidth),
              4: const pw.FixedColumnWidth(BillPdfLayout.rateWidth),
              5: const pw.FixedColumnWidth(BillPdfLayout.amountWidth),
            },
            border: const pw.TableBorder(
              top: pw.BorderSide(color: _rule, width: 0.5),
              bottom: pw.BorderSide(color: _rule, width: 0.5),
              horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
            ),
            children: rows,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Spacer(),
              pw.SizedBox(
                width: 240,
                child: pw.Column(
                  children: [
                    totalLine(l.totalQty, '${bill.totalQty}'),
                    if ((bill.totalWeightMg ?? 0) > 0) totalLine(l.totalWeight, AppFormat.grams(bill.totalWeightMg!)),
                    pw.Divider(color: _rule, thickness: 0.5),
                    totalLine(l.total, money(bill.total), strong: true),
                    if (!bill.paid.isZero) totalLine(l.paid, money(bill.paid)),
                    pw.Divider(color: _rule, thickness: 0.5),
                    totalLine(l.bakiAfter, baki, strong: true),
                  ],
                ),
              ),
            ],
          ),
          if ((b.footer ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Center(
              child: text(b.footer!, BillText.small, color: _muted, align: pw.TextAlign.center),
            ),
          ],
        ],
      ),
    );
  return doc.save();
}
