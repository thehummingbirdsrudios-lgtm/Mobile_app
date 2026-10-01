import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Captures the widget under [key] (a [RepaintBoundary]) as a PNG. Flutter
/// shapes Gujarati and Devanagari correctly, so documents are rendered as
/// widgets and captured, never typeset as PDF text.
typedef WidgetCapturer = Future<Uint8List> Function(GlobalKey key, {double pixelRatio});

Future<Uint8List> captureBoundary(GlobalKey key, {double pixelRatio = 3}) async {
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) throw StateError('No RepaintBoundary to capture');
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Seam for widget tests (fake time cannot await a real raster).
final widgetCapturerProvider = Provider<WidgetCapturer>((ref) => captureBoundary);

@immutable
class ImagePdfInput {
  const ImagePdfInput({required this.png, required this.title});

  final Uint8List png;
  final String title;
}

/// Wraps one tall image into a single-page PDF (A4 width, height to fit),
/// in a background isolate.
Future<Uint8List> buildImagePdf(ImagePdfInput input) => compute(renderImagePdf, input);

/// Pure version (public for tests).
Future<Uint8List> renderImagePdf(ImagePdfInput input) async {
  final image = pw.MemoryImage(input.png);
  final width = PdfPageFormat.a4.width;
  final height = width * image.height! / image.width!;
  final doc = pw.Document(title: input.title, creator: 'Vepari')
    ..addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height),
        build: (_) => pw.Image(image, fit: pw.BoxFit.contain),
      ),
    );
  return doc.save();
}

typedef PdfBuilder = Future<Uint8List> Function(ImagePdfInput input);

/// Seam for widget tests.
final pdfBuilderProvider = Provider<PdfBuilder>((ref) => buildImagePdf);
