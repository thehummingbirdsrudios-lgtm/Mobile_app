import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../domain/sharing.dart';

/// Overridden at the composition root and in tests.
final sharingRepositoryProvider = Provider<SharingRepository>(
  (ref) => throw UnimplementedError('sharingRepositoryProvider must be overridden'),
);

@immutable
class ShareOptions {
  const ShareOptions({this.showRate = true, this.watermark = true, this.customerId});

  final bool showRate;
  final bool watermark;
  final String? customerId;
}

/// Caption text for the shared designs (localised by the caller).
typedef CaptionBuilder = String Function(List<ShareableProduct> products, ShareOptions options);

/// Result of a share attempt.
enum ShareOutcome { shared, sharedTextOnly, unavailable }

final productSharerProvider = Provider<ProductSharer>(ProductSharer.new);

class ProductSharer {
  ProductSharer(this._ref);

  final Ref _ref;

  /// Fetches the share-safe data for each design, prepares its photo
  /// (watermarked if the business enabled it and the user kept it on) and
  /// opens the share sheet with one caption.
  Future<ShareOutcome> share(List<String> productIds, ShareOptions options, CaptionBuilder caption) async {
    final repo = _ref.read(sharingRepositoryProvider);
    final products = await Future.wait([for (final id in productIds) repo.product(id, customerId: options.customerId)]);
    final composer = _ref.read(shareImageComposerProvider);
    final files = <ShareFile>[];
    for (final p in products) {
      final path = p.sharePath;
      if (path == null) continue;
      final bytes = Uint8List.fromList(await repo.photo(path));
      final stamped = await composer(bytes, watermark: options.watermark && p.watermark ? p.businessName : null);
      files.add(ShareFile(bytes: stamped, name: '${_safeName(p.designNo)}.jpg', mimeType: 'image/jpeg'));
    }
    final ok = await _ref.read(fileSharerProvider).share(files: files, text: caption(products, options));
    if (!ok) return ShareOutcome.unavailable;
    return files.isEmpty ? ShareOutcome.sharedTextOnly : ShareOutcome.shared;
  }

  static String _safeName(String designNo) => designNo.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}
