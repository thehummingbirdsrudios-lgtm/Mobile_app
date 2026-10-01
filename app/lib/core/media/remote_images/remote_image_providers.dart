import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../config/app_config.dart';
import '../../logging/logger_provider.dart';
import '../../widgets/remote_image.dart' show signedUrlCacheProvider;
import 'image_cache_service.dart';
import 'image_fetch_service.dart';
import 'image_source_service.dart';
import 'optimized_image_loader.dart';

final imageHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Downloads are allowed from our own storage host only.
final imageFetchPolicyProvider = Provider<ImageFetchPolicy>((ref) {
  final host = Uri.tryParse(ref.watch(appConfigProvider).supabaseUrl)?.host.toLowerCase() ?? '';
  return ImageFetchPolicy(allowedHosts: {if (host.isNotEmpty) host});
});

final imageCacheServiceProvider = Provider<ImageCacheService>(
  (ref) => TieredImageCache(
    MemoryImageCache(),
    DiskImageCache(() async => Directory('${(await getApplicationSupportDirectory()).path}/image-cache/v1')),
  ),
);

final optimizedImageLoaderProvider = Provider<OptimizedImageLoader>(
  (ref) => OptimizedImageLoader(
    source: SignedImageSource(ref.watch(signedUrlCacheProvider)),
    fetcher: ImageFetchService(ref.watch(imageHttpClientProvider), policy: ref.watch(imageFetchPolicyProvider)),
    cache: ref.watch(imageCacheServiceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);
