import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tokens.dart';
import '../network/storage_client.dart';

typedef StorageKey = ({String bucket, String path});

/// Signed-URL cache: URLs are valid for 60 minutes and reused for 45.
/// No timers — expiry is checked on read; concurrent requests for the same
/// object share one signing call. Keys are tenant-prefixed storage paths, and
/// the app invalidates this provider whenever the signed-in identity changes.
class SignedUrlCache {
  SignedUrlCache(this._storage, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const reuseFor = Duration(minutes: 45);
  static const maxEntries = 2000;

  final StorageClient _storage;
  final DateTime Function() _clock;
  final _entries = <String, ({String url, DateTime expires})>{};
  final _inFlight = <String, Future<String>>{};

  Future<String> get(StorageKey key) {
    final id = '${key.bucket}/${key.path}';
    final hit = _entries[id];
    if (hit != null && _clock().isBefore(hit.expires)) return Future.value(hit.url);
    return _inFlight[id] ??= _storage
        .signedUrl(key.bucket, key.path)
        .then((url) {
          if (_entries.length >= maxEntries) _entries.remove(_entries.keys.first);
          _entries[id] = (url: url, expires: _clock().add(reuseFor));
          return url;
        })
        .whenComplete(() => _inFlight.remove(id));
  }
}

final signedUrlCacheProvider = Provider<SignedUrlCache>((ref) => SignedUrlCache(ref.watch(storageClientProvider)));

final signedUrlProvider = FutureProvider.autoDispose.family<String, StorageKey>(
  (ref, key) => ref.watch(signedUrlCacheProvider).get(key),
);

/// Renders a resolved image URL. Swappable so tests never touch the network.
typedef NetworkImageBuilder = Widget Function({
  required String url,
  required String cacheKey,
  required BoxFit fit,
  int? cacheWidth,
  String? semanticLabel,
});

Widget _cachedNetworkImage({
  required String url,
  required String cacheKey,
  required BoxFit fit,
  int? cacheWidth,
  String? semanticLabel,
}) => CachedNetworkImage(
  imageUrl: url,
  cacheKey: cacheKey,
  fit: fit,
  memCacheWidth: cacheWidth,
  fadeInDuration: const Duration(milliseconds: 120),
  placeholder: (_, _) => const _ImagePlaceholder(),
  errorWidget: (_, _, _) => const _ImagePlaceholder(icon: Icons.broken_image_outlined),
  imageBuilder: semanticLabel == null
      ? null
      : (context, provider) => Semantics(
          image: true,
          label: semanticLabel,
          child: Image(image: provider, fit: fit),
        ),
);

final networkImageBuilderProvider = Provider<NetworkImageBuilder>((ref) => _cachedNetworkImage);

/// A private storage image: signed URL → disk/memory cache keyed by the
/// storage path (stable across URL re-signing) → decoded at display size.
class RemoteImage extends ConsumerWidget {
  const RemoteImage({
    super.key,
    required this.path,
    this.bucket = Buckets.productMedia,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    this.semanticLabel,
  });

  final String? path;
  final String bucket;
  final BoxFit fit;

  /// Logical width the image is displayed at; decoding is capped to it × DPR
  /// so a 256 px thumbnail never costs a 4000 px bitmap in memory.
  final double? decodeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = path;
    if (p == null || p.isEmpty) return const _ImagePlaceholder(icon: Icons.diamond_outlined);
    final url = ref.watch(signedUrlProvider((bucket: bucket, path: p)));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = decodeWidth == null ? null : (decodeWidth! * dpr).round();
    return switch (url) {
      AsyncData(:final value) => ref.watch(networkImageBuilderProvider)(
        url: value,
        cacheKey: '$bucket/$p',
        fit: fit,
        cacheWidth: cacheWidth,
        semanticLabel: semanticLabel,
      ),
      AsyncError() => const _ImagePlaceholder(icon: Icons.broken_image_outlined),
      _ => const _ImagePlaceholder(),
    };
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceMuted,
    child: icon == null ? const SizedBox.expand() : Center(child: Icon(icon, color: AppColors.muted, size: 28)),
  );
}
