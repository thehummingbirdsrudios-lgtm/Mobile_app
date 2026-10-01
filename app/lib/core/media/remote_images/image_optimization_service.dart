import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'image_models.dart';
import 'image_validation_service.dart';

@immutable
class OptimizeJob {
  const OptimizeJob(this.bytes, this.spec);

  final Uint8List bytes;
  final ImageSpec spec;
}

typedef OptimizeRunner = Future<OptimizedImage> Function(OptimizeJob job);

Future<OptimizedImage> _inIsolate(OptimizeJob job) => compute(optimizeImage, job);

/// Makes a small, sharp JPEG for display at a known size. Runs off the UI
/// isolate; only the result travels back, so the decoded original is freed
/// as soon as each image is done.
class ImageOptimizationService {
  const ImageOptimizationService({this._runner = _inIsolate});

  final OptimizeRunner _runner;

  Future<OptimizedImage> optimize(Uint8List bytes, ImageSpec spec) => _runner(OptimizeJob(bytes, spec));
}

/// Pure pipeline (public for tests): decode → upright (EXIF) → flatten any
/// transparency onto white → downscale (never upscale) keeping the aspect
/// ratio → JPEG with full-resolution colour (4:4:4) so fine jewellery
/// detail stays crisp → no metadata.
OptimizedImage optimizeImage(OptimizeJob job) {
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) throw const InvalidImageException(InvalidImageReason.corrupt);
  var image = img.bakeOrientation(decoded);
  if (image.hasAlpha) {
    final flat = img.Image(width: image.width, height: image.height)..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(flat, image);
  }
  final longest = math.max(image.width, image.height);
  final edge = job.spec.maxEdgePx;
  if (longest > edge) {
    final scale = edge / longest;
    // Area averaging for big reductions (no aliasing), cubic otherwise (sharp).
    final interpolation = scale < 0.5 ? img.Interpolation.average : img.Interpolation.cubic;
    image = image.width >= image.height
        ? img.copyResize(image, width: edge, interpolation: interpolation)
        : img.copyResize(image, height: edge, interpolation: interpolation);
  }
  image.exif = img.ExifData(); // no camera metadata (location, device) in shared documents
  final jpeg = img.encodeJpg(image, quality: job.spec.jpegQuality, chroma: img.JpegChroma.yuv444);
  return OptimizedImage(jpeg: jpeg, width: image.width, height: image.height);
}
