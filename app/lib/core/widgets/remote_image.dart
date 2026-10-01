import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tokens.dart';
import '../network/storage_client.dart';

typedef StorageKey = ({String bucket, String path});

/// Signed URLs are cached for 45 minutes (they are valid for 60). Keys are
/// tenant-prefixed storage paths, so entries can never be shared across
/// businesses; the app also invalidates this provider on sign-out.
final signedUrlProvider = FutureProvider.autoDispose.family<String, StorageKey>((ref, key) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 45), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(storageClientProvider).signedUrl(key.bucket, key.path);
});

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
      AsyncData(:final value) => CachedNetworkImage(
        imageUrl: value,
        cacheKey: '$bucket/$p',
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
