import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/catalogue.dart';

/// Overridden at the composition root and in tests.
final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => throw UnimplementedError('catalogueRepositoryProvider must be overridden'),
);

typedef CatalogueState = PagedState<ProductSummary, CatalogueCursor>;

/// Infinite catalogue for one filter (all, a category, or Navo Maal).
final catalogueFeedProvider = NotifierProvider.autoDispose.family<CatalogueFeed, CatalogueState, CatalogueFilter>(
  CatalogueFeed.new,
);

class CatalogueFeed extends Notifier<CatalogueState> {
  CatalogueFeed(this.filter);

  final CatalogueFilter filter;
  Paginator<ProductSummary, CatalogueCursor>? _paginator;

  @override
  CatalogueState build() {
    // A different signed-in business must never see this list.
    ref.watch(currentSessionProvider.select((s) => s?.tenantId));
    final paginator = Paginator<ProductSummary, CatalogueCursor>(
      (cursor) => ref.read(catalogueRepositoryProvider).page(filter, after: cursor),
      (s) {
        if (ref.mounted) state = s;
      },
    );
    _paginator = paginator;
    unawaited(Future.microtask(paginator.refresh));
    return const CatalogueState();
  }

  Future<void> refresh() => _paginator?.refresh() ?? Future.value();
  Future<void> loadMore() => _paginator?.loadMore() ?? Future.value();
  Future<void> retry() => _paginator?.retry() ?? Future.value();
}

final productDetailProvider = FutureProvider.autoDispose.family<ProductDetail?, String>((ref, id) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(catalogueRepositoryProvider).detail(id);
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(catalogueRepositoryProvider).categories();
});

/// Write operations for the design editor. Keeps screens free of data logic
/// and refreshes every affected read after a change. Not autoDispose: the
/// service is stateless and must outlive the awaits inside its own methods.
final productEditorProvider = Provider<ProductEditorService>(ProductEditorService.new);

class ProductEditorService {
  ProductEditorService(this._ref);

  final Ref _ref;

  CatalogueRepository get _repo => _ref.read(catalogueRepositoryProvider);

  Future<String> create(ProductDraft draft) async {
    final session = _ref.read(currentSessionProvider);
    final id = await _repo.create(draft, includePrivate: session?.isOwner ?? false);
    _invalidateLists();
    return id;
  }

  Future<void> update(String id, ProductDraft draft, {required bool rateChanged}) async {
    final session = _ref.read(currentSessionProvider);
    await _repo.update(
      id,
      draft,
      includeRate: rateChanged && (session?.can(Permission.ratesManage) ?? false),
      includePrivate: session?.isOwner ?? false,
    );
    _invalidate(id);
  }

  Future<Category> createCategory(String name) async {
    final category = await _repo.createCategory(name);
    _ref.invalidate(categoriesProvider);
    return category;
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    await _repo.setArchived(id, archived: archived);
    _invalidate(id);
  }

  /// Validates and processes [bytes] in a background isolate, then uploads.
  Future<void> addPhoto(String productId, Uint8List bytes, {required int sortOrder}) async {
    final tenantId = _ref.read(currentSessionProvider)?.tenantId;
    if (tenantId == null) throw const AppFailure(FailureKind.sessionExpired);
    final d = await _ref.read(imageProcessorProvider)(bytes);
    await _repo.addPhoto(
      productId,
      PhotoUpload(
        tenantId: tenantId,
        original: d.original,
        originalMime: d.originalMime,
        catalogue: d.catalogue,
        share: d.share,
        thumb: d.thumb,
        width: d.width,
        height: d.height,
        sha256: d.sha256,
        sortOrder: sortOrder,
      ),
    );
    _invalidate(productId);
  }

  Future<void> removePhoto(String productId, String photoId) async {
    await _repo.removePhoto(photoId);
    _invalidate(productId);
  }

  void _invalidate(String id) {
    _ref.invalidate(productDetailProvider(id));
    _invalidateLists();
  }

  void _invalidateLists() => _ref.invalidate(catalogueFeedProvider);
}
