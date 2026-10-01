import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../logging/app_logger.dart';
import 'image_cache_service.dart';
import 'image_fetch_service.dart';
import 'image_models.dart';
import 'image_optimization_service.dart';
import 'image_source_service.dart';
import 'image_validation_service.dart';

/// Orchestrates: cache → resolve source → fetch → validate → optimise →
/// cache. Image problems never throw: a missing or broken photo returns
/// null (the caller shows a placeholder) and is logged with its storage key
/// and label — never with the signed URL, which carries a token.
class OptimizedImageLoader {
  OptimizedImageLoader({
    required this._source,
    required this._fetcher,
    required this._cache,
    required this._logger,
    this._validator = const ImageValidationService(),
    this._optimizer = const ImageOptimizationService(),
  });

  final ImageSourceService _source;
  final ImageFetchService _fetcher;
  final ImageCacheService _cache;
  final AppLogger _logger;
  final ImageValidationService _validator;
  final ImageOptimizationService _optimizer;

  Future<OptimizedImage?> load(ImageRef ref, ImageSpec spec, {String? label}) async {
    final key = optimizedImageCacheKey(ref, spec);
    try {
      final cached = await _cache.read(key);
      if (cached != null) {
        final info = img.JpegDecoder().startDecode(cached);
        if (info != null) return OptimizedImage(jpeg: cached, width: info.width, height: info.height);
      }
      final uri = await _source.resolve(ref);
      final original = await _fetcher.fetch(uri);
      _validator.validate(original);
      final optimized = await _optimizer.optimize(original, spec);
      await _cache.write(key, optimized.jpeg);
      return optimized;
    } on Object catch (error) {
      _logger.warning('image.load_failed', {
        'image': ref.id, // storage key only
        'label': ?label,
        'reason': switch (error) {
          ImageFetchException(:final reason, :final status) => '${reason.name}${status == null ? '' : ':$status'}',
          InvalidImageException(:final reason) => reason.name,
          _ => error.runtimeType.toString(),
        },
      });
      return null;
    }
  }

  /// Loads many images with at most [concurrency] in flight (memory stays
  /// bounded: each worker holds one original at a time). Duplicate refs are
  /// processed once. Missing/failed images are simply absent from the map.
  Future<Map<ImageRef, OptimizedImage>> loadAll(
    Iterable<ImageRef> refs,
    ImageSpec spec, {
    Map<ImageRef, String> labels = const {},
    int concurrency = 3,
  }) async {
    final queue = refs.toSet().toList();
    final results = <ImageRef, OptimizedImage>{};
    var next = 0;
    Future<void> worker() async {
      while (next < queue.length) {
        final ref = queue[next++];
        final image = await load(ref, spec, label: labels[ref]);
        if (image != null) results[ref] = image;
      }
    }

    await Future.wait([for (var i = 0; i < math.min(concurrency, queue.length); i++) worker()]);
    return results;
  }
}
