import 'package:meta/meta.dart';

import '../../../core/money/money.dart';

/// A design as it may be shown outside the app. Built only from
/// `share_product`, whose allow-list never includes cost, supplier, internal
/// notes, stock or other customers' rates — there is no field for them here.
@immutable
class ShareableProduct {
  const ShareableProduct({
    required this.designNo,
    required this.name,
    required this.rate,
    required this.businessName,
    required this.watermark,
    this.weightMg,
    this.sharePath,
    this.whatsappPhone,
  });

  final String designNo;
  final String name;
  final Money rate;
  final int? weightMg;
  final String? sharePath;
  final String businessName;
  final String? whatsappPhone;
  final bool watermark;
}

/// Sharing port. Implementations throw `AppFailure`.
abstract interface class SharingRepository {
  /// [customerId] prices the design at that customer's rate.
  Future<ShareableProduct> product(String productId, {String? customerId});

  /// The share-sized photo (1280px JPEG).
  Future<List<int>> photo(String sharePath);
}
