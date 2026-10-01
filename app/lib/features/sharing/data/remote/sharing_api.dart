import 'dart:typed_data';

import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/storage_client.dart';
import '../../domain/sharing.dart';

class SharingApi {
  const SharingApi(this._api, this._storage);

  final ApiClient _api;
  final StorageClient _storage;

  Future<ShareableProduct> product(String productId, {String? customerId}) => _api.rpc(
    'share_product',
    params: {'p_product_id': productId, 'p_customer_id': customerId},
    decode: (json) => shareableProductFromJson(asJsonObject(json)),
  );

  Future<Uint8List> photo(String sharePath) => _storage.download(Buckets.productMedia, sharePath);
}

ShareableProduct shareableProductFromJson(Map<String, dynamic> j) => ShareableProduct(
  designNo: j.requireString('design_no'),
  name: j.requireString('name'),
  rate: Money.paise(j.requireInt('rate_paise')),
  weightMg: j.optionalInt('weight_mg'),
  sharePath: j.optionalString('share_path'),
  businessName: j.optionalString('business_name') ?? '',
  whatsappPhone: j.optionalString('whatsapp_phone'),
  watermark: j['watermark_enabled'] == true,
);
