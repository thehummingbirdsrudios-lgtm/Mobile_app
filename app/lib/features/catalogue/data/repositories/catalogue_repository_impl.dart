import '../../../../core/state/paged.dart';
import '../../domain/catalogue.dart';
import '../remote/catalogue_api.dart';
import '../remote/catalogue_dto.dart';

class CatalogueRepositoryImpl implements CatalogueRepository {
  CatalogueRepositoryImpl(this._remote);

  final CatalogueApi _remote;

  @override
  Future<PageResult<ProductSummary, CatalogueCursor>> page(
    CatalogueFilter filter, {
    CatalogueCursor? after,
    int limit = 30,
  }) => _remote.page(filter, after: after, limit: limit);

  @override
  Future<ProductDetail?> detail(String productId) => _remote.detail(productId);

  @override
  Future<List<Category>> categories() => _remote.categories();

  @override
  Future<Category> createCategory(String name) => _remote.insertCategory(name);

  @override
  Future<String> create(ProductDraft draft, {required bool includePrivate}) async {
    final id = await _remote.insertProduct(productColumns(draft, includeRate: true));
    if (includePrivate && draft.hasPrivateData) await _remote.savePrivate(id, privateColumns(draft));
    return id;
  }

  @override
  Future<void> update(
    String productId,
    ProductDraft draft, {
    required bool includeRate,
    required bool includePrivate,
  }) async {
    await _remote.updateProduct(productId, productColumns(draft, includeRate: includeRate));
    if (includePrivate) await _remote.savePrivate(productId, privateColumns(draft));
  }

  @override
  Future<void> setArchived(String productId, {required bool archived}) => _remote.updateProduct(productId, {
    'status': archived ? 'archived' : 'active',
    'archived_at': archived ? DateTime.now().toUtc().toIso8601String() : null,
  });

  @override
  Future<void> addPhoto(String productId, PhotoUpload upload) => _remote.insertPhoto(productId, upload);

  @override
  Future<void> removePhoto(String photoId) => _remote.archivePhoto(photoId);
}
