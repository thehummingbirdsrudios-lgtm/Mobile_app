import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../design/tokens.dart';
import 'image_pipeline.dart' show ImageLimits;

/// Prepares a product photo for sharing: optionally stamps the business name
/// in the corner (drawn by Flutter so Gujarati/Hindi names are shaped
/// correctly) and returns a JPEG. Without a watermark the stored share
/// derivative is returned untouched.
typedef ShareImageComposer = Future<Uint8List> Function(Uint8List jpeg, {String? watermark});

Future<Uint8List> composeShareImage(Uint8List jpeg, {String? watermark}) async {
  if (watermark == null || watermark.trim().isEmpty) return jpeg;
  final codec = await ui.instantiateImageCodec(jpeg);
  final source = (await codec.getNextFrame()).image;
  codec.dispose();
  try {
    final w = source.width.toDouble();
    final h = source.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w, h))..drawImage(source, ui.Offset.zero, ui.Paint());
    final painter = TextPainter(
      text: TextSpan(
        text: watermark.trim(),
        style: TextStyle(
          fontFamily: AppType.family,
          fontFamilyFallback: AppType.fallback,
          fontSize: (w / 22).clamp(14, 64),
          fontWeight: FontWeight.w600,
          color: const ui.Color(0xD9FFFFFF),
          shadows: const [ui.Shadow(color: ui.Color(0x99000000), blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: w * 0.8);
    final pad = w * 0.03;
    painter.paint(canvas, ui.Offset(w - painter.width - pad, h - painter.height - pad));
    painter.dispose();
    final stamped = await recorder.endRecording().toImage(source.width, source.height);
    try {
      final rgba = await stamped.toByteData(format: ui.ImageByteFormat.rawRgba);
      return await compute(_encodeJpeg, (rgba!.buffer.asUint8List(), source.width, source.height));
    } finally {
      stamped.dispose();
    }
  } finally {
    source.dispose();
  }
}

Uint8List _encodeJpeg((Uint8List, int, int) input) {
  final (rgba, width, height) = input;
  final image = img.Image.fromBytes(width: width, height: height, bytes: rgba.buffer, numChannels: 4);
  return img.encodeJpg(image, quality: ImageLimits.jpegQuality);
}

/// Seam for widget tests (fake time cannot await a real raster).
final shareImageComposerProvider = Provider<ShareImageComposer>((ref) => composeShareImage);
