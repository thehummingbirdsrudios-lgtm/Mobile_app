import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tokens.dart';

/// Text drawn by Flutter's text engine, for documents whose own typesetter
/// cannot shape the script (the `pdf` package has no Gujarati/Devanagari
/// conjunct shaping). Sizes are in points.
@immutable
class RasterText {
  const RasterText({required this.png, required this.width, required this.height});

  final Uint8List png;
  final double width;
  final double height;
}

typedef TextRasterizer = Future<RasterText> Function(
  String text, {
  required double fontSize,
  bool bold,
  double maxWidth,
  int maxLines,
});

/// True when [text] contains an Indic script (needs real shaping).
bool needsShaping(String text) => text.runes.any((r) => r >= 0x0900 && r <= 0x0DFF);

/// Renders [text] at 4× (≈ 288 dpi) on a transparent background.
Future<RasterText> rasterizeText(
  String text, {
  required double fontSize,
  bool bold = false,
  double maxWidth = 400,
  int maxLines = 2,
}) async {
  const scale = 4.0;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: AppType.family,
        fontFamilyFallback: AppType.fallback,
        fontSize: fontSize * scale,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: const ui.Color(0xFF1B1A17),
        height: 1.25,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth * scale);
  final w = painter.width.ceil().clamp(1, 1 << 14);
  final h = painter.height.ceil().clamp(1, 1 << 14);
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), ui.Offset.zero);
  final width = painter.width / scale;
  final height = painter.height / scale;
  painter.dispose();
  final image = await recorder.endRecording().toImage(w, h);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return RasterText(png: data!.buffer.asUint8List(), width: width, height: height);
  } finally {
    image.dispose();
  }
}

final textRasterizerProvider = Provider<TextRasterizer>((ref) => rasterizeText);
