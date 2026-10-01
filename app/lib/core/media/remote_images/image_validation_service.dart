import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum SourceImageFormat { jpeg, png, webp, gif, bmp }

@immutable
class ImageFacts {
  const ImageFacts({required this.format, required this.width, required this.height});

  final SourceImageFormat format;
  final int width;
  final int height;
}

enum InvalidImageReason { unsupportedFormat, corrupt, tooManyPixels }

class InvalidImageException implements Exception {
  const InvalidImageException(this.reason);

  final InvalidImageReason reason;

  @override
  String toString() => 'InvalidImageException($reason)';
}

/// Checks downloaded bytes are really an image we can handle, by their
/// content (never by file name or claimed type), and that decoding it will
/// not exhaust memory.
class ImageValidationService {
  const ImageValidationService({this.maxDimension = 12000, this.maxPixels = 25000000});

  final int maxDimension;

  /// 25 MP ≈ 100 MB once decoded; anything bigger is refused.
  final int maxPixels;

  ImageFacts validate(Uint8List bytes) {
    final decoder = img.findDecoderForData(bytes);
    final format = switch (decoder) {
      img.JpegDecoder() => SourceImageFormat.jpeg,
      img.PngDecoder() => SourceImageFormat.png,
      img.WebPDecoder() => SourceImageFormat.webp,
      img.GifDecoder() => SourceImageFormat.gif,
      img.BmpDecoder() => SourceImageFormat.bmp,
      _ => throw const InvalidImageException(InvalidImageReason.unsupportedFormat),
    };
    final info = decoder!.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) {
      throw const InvalidImageException(InvalidImageReason.corrupt);
    }
    if (info.width > maxDimension || info.height > maxDimension || info.width * info.height > maxPixels) {
      throw const InvalidImageException(InvalidImageReason.tooManyPixels);
    }
    return ImageFacts(format: format, width: info.width, height: info.height);
  }
}
