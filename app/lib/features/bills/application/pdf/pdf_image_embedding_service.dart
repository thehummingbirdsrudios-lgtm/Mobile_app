import 'dart:typed_data';

import '../../../../core/media/remote_images/image_models.dart';
import '../../../../core/media/remote_images/optimized_image_loader.dart';
import '../../../../core/network/storage_client.dart' show Buckets;
import '../../domain/bills.dart';
import 'bill_pdf_layout.dart';

/// Prepares the photo of every bill line for embedding: one optimised JPEG
/// per distinct source (a design on many lines is fetched and embedded
/// once), at most [concurrency] downloads in flight, and lines whose photo
/// is missing or broken simply have no entry (the bill shows a placeholder).
class PdfImageEmbeddingService {
  const PdfImageEmbeddingService(this._loader, {this.concurrency = 3});

  final OptimizedImageLoader _loader;
  final int concurrency;

  /// Source key → optimised JPEG.
  Future<Map<String, Uint8List>> prepare(List<BillItem> items, BillImageTier tier) async {
    final labels = <ImageRef, String>{
      for (final item in items)
        if (item.imagePath case final path?) ImageRef(bucket: Buckets.productMedia, path: path): item.designNo,
    };
    final loaded = await _loader.loadAll(labels.keys, tier.spec, labels: labels, concurrency: concurrency);
    return {for (final e in loaded.entries) e.key.path: e.value.jpeg};
  }
}
