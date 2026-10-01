import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// Upload limits (mirror the product-media bucket: 25 MB, images only).
abstract final class ImageLimits {
  static const maxBytes = 25 * 1024 * 1024;
  static const maxDimension = 12000;
  static const catalogueEdge = 800;
  static const shareEdge = 1280;
  static const thumbEdge = 256;
  static const jpegQuality = 82;
}

enum ImageRejection { tooLarge, notAnImage, tooManyPixels }

class ImageRejectedException implements Exception {
  const ImageRejectedException(this.reason);

  final ImageRejection reason;

  @override
  String toString() => 'ImageRejectedException($reason)';
}

/// The derivatives stored for every product photo (ADR-0006). Produced once,
/// at upload, off the UI isolate.
@immutable
class ImageDerivatives {
  const ImageDerivatives({
    required this.original,
    required this.originalMime,
    required this.catalogue,
    required this.share,
    required this.thumb,
    required this.width,
    required this.height,
    required this.sha256,
  });

  final Uint8List original;
  final String originalMime;
  final Uint8List catalogue;
  final Uint8List share;
  final Uint8List thumb;
  final int width;
  final int height;
  final String sha256;
}

/// Validates and processes a picked photo in a background isolate.
Future<ImageDerivatives> buildImageDerivatives(Uint8List original) => compute(processImage, original);

typedef ImageProcessor = Future<ImageDerivatives> Function(Uint8List original);

/// Seam for widget tests, which cannot await a real isolate under fake time.
final imageProcessorProvider = Provider<ImageProcessor>((ref) => buildImageDerivatives);

/// Pure, synchronous pipeline (public for tests). Validates by decoding the
/// actual bytes — never trusts a file name or a claimed MIME type.
ImageDerivatives processImage(Uint8List original) {
  if (original.lengthInBytes > ImageLimits.maxBytes) throw const ImageRejectedException(ImageRejection.tooLarge);
  final decoder = img.findDecoderForData(original);
  final mime = switch (decoder) {
    img.JpegDecoder() => 'image/jpeg',
    img.PngDecoder() => 'image/png',
    img.WebPDecoder() => 'image/webp',
    _ => null,
  };
  if (mime == null) throw const ImageRejectedException(ImageRejection.notAnImage);
  final info = decoder!.startDecode(original);
  if (info == null) throw const ImageRejectedException(ImageRejection.notAnImage);
  if (info.width > ImageLimits.maxDimension || info.height > ImageLimits.maxDimension) {
    throw const ImageRejectedException(ImageRejection.tooManyPixels);
  }
  final decoded = decoder.decode(original);
  if (decoded == null) throw const ImageRejectedException(ImageRejection.notAnImage);
  // Apply EXIF orientation so derivatives are upright; derivatives carry no EXIF.
  final upright = img.bakeOrientation(decoded);

  Uint8List derive(int edge) {
    final longest = upright.width >= upright.height ? upright.width : upright.height;
    final resized = longest <= edge
        ? upright
        : upright.width >= upright.height
        ? img.copyResize(upright, width: edge, interpolation: img.Interpolation.average)
        : img.copyResize(upright, height: edge, interpolation: img.Interpolation.average);
    return img.encodeJpg(resized, quality: ImageLimits.jpegQuality);
  }

  return ImageDerivatives(
    original: original,
    originalMime: mime,
    catalogue: derive(ImageLimits.catalogueEdge),
    share: derive(ImageLimits.shareEdge),
    thumb: derive(ImageLimits.thumbEdge),
    width: upright.width,
    height: upright.height,
    sha256: sha256.convert(original).toString(),
  );
}
