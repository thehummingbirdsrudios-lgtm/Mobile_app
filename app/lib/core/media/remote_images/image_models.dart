import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Where an image lives: a key in one of the private storage buckets. This
/// is the canonical image source stored in the database (product_media);
/// URLs are derived from it on demand and never stored.
@immutable
class ImageRef {
  const ImageRef({required this.bucket, required this.path});

  final String bucket;
  final String path;

  String get id => '$bucket/$path';

  @override
  bool operator ==(Object other) => other is ImageRef && other.bucket == bucket && other.path == path;

  @override
  int get hashCode => Object.hash(bucket, path);

  @override
  String toString() => id;
}

/// What an optimised copy must look like: the longest edge in pixels (sized
/// to where the image is shown) and the JPEG quality.
@immutable
class ImageSpec {
  const ImageSpec({required this.maxEdgePx, this.jpegQuality = 86});

  final int maxEdgePx;
  final int jpegQuality;

  String get id => 'e${maxEdgePx}q$jpegQuality';

  @override
  bool operator ==(Object other) =>
      other is ImageSpec && other.maxEdgePx == maxEdgePx && other.jpegQuality == jpegQuality;

  @override
  int get hashCode => Object.hash(maxEdgePx, jpegQuality);
}

/// A small JPEG ready to embed (no metadata, sRGB, no alpha).
@immutable
class OptimizedImage {
  const OptimizedImage({required this.jpeg, required this.width, required this.height});

  final Uint8List jpeg;
  final int width;
  final int height;
}

/// Cache key for an optimised copy. Storage keys are write-once (a new
/// photo gets a new key), so source + spec identify the content exactly.
String optimizedImageCacheKey(ImageRef ref, ImageSpec spec) =>
    sha256.convert(utf8.encode('v1|${ref.id}|${spec.id}')).toString();
