import '../../domain/sharing.dart';
import '../remote/sharing_api.dart';

class SharingRepositoryImpl implements SharingRepository {
  const SharingRepositoryImpl(this._remote);

  final SharingApi _remote;

  @override
  Future<ShareableProduct> product(String productId, {String? customerId}) =>
      _remote.product(productId, customerId: customerId);

  @override
  Future<List<int>> photo(String sharePath) => _remote.photo(sharePath);
}
