import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
