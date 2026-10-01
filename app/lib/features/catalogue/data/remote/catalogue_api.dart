import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/storage_client.dart';
import '../../../../core/state/paged.dart';
import '../../../../core/util/ids.dart';
import '../../domain/catalogue.dart';
import 'catalogue_dto.dart';

/// Remote data source for the catalogue: read RPCs, RLS-protected table
/// writes and private storage uploads.
class CatalogueApi {
  CatalogueApi(this._client, this._api, this._storage);

  final SupabaseClient _client;
  final ApiClient _api;
  final StorageClient _storage;

  Future<PageResult<ProductSummary, CatalogueCursor>> page(
    CatalogueFilter filter, {
    CatalogueCursor? after,
    required int limit,
  }) async {
    final rows = await _api.rpc(
      'catalogue_page',
      params: {
        'p_after_published_at': after?.publishedAt.toUtc().toIso8601String(),
        'p_after_id': after?.id,
        'p_limit': limit,
        'p_category_id': filter.categoryId,
        'p_new_since': filter.newSince?.toUtc().toIso8601String(),
      },
      decode: (json) => [for (final r in (json! as List)) productSummaryFromJson(asJsonObject(r))],
    );
    final next = rows.length < limit ? null : (publishedAt: rows.last.publishedAt, id: rows.last.id);
    return PageResult(rows, next: next);
  }

  Future<ProductDetail?> detail(String id) => _api.rpc(
    'product_detail',
    params: {'p_product_id': id},
    decode: (json) => json == null ? null : productDetailFromJson(asJsonObject(json)),
  );

  Future<List<Category>> categories() => _api.run(
    'categories.list',
    () async => [
      for (final r
          in await _client
              .from('categories')
              .select('id,name')
              .isFilter('archived_at', null)
              .order('sort_order')
              .order('name')
              .limit(200))
        Category(id: r.requireString('id'), name: r.requireString('name')),
    ],
  );

  Future<Category> insertCategory(String name) => _api.run('categories.insert', () async {
    final r = await _client.from('categories').insert({'name': name.trim()}).select('id,name').single();
    return Category(id: r.requireString('id'), name: r.requireString('name'));
  });

  Future<String> insertProduct(Map<String, Object?> columns) => _api.run(
    'products.insert',
    () async => (await _client.from('products').insert(columns).select('id').single()).requireString('id'),
  );

  Future<void> updateProduct(String id, Map<String, Object?> columns) => _api.run('products.update', () async {
    final rows = await _client.from('products').update(columns).eq('id', id).select('id');
    if (rows.isEmpty) throw const AppFailure(FailureKind.permissionDenied);
  });

  /// Owner-only table: update the existing row, or insert the first one.
  Future<void> savePrivate(String productId, Map<String, Object?> columns) =>
      _api.run('product_private.save', () async {
        final updated = await _client
            .from('product_private')
            .update(columns)
            .eq('product_id', productId)
            .select('product_id');
        if (updated.isEmpty) await _client.from('product_private').insert({...columns, 'product_id': productId});
      });

  Future<void> insertPhoto(String productId, PhotoUpload u) async {
    final folder = '${u.tenantId}/products/$productId/${newUuid()}';
    final ext = switch (u.originalMime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final paths = (
      original: '$folder/original.$ext',
      catalogue: '$folder/catalogue.jpg',
      share: '$folder/share.jpg',
      thumb: '$folder/thumb.jpg',
    );
    await _storage.upload(
      Buckets.productMedia,
      paths.original,
      Uint8List.fromList(u.original),
      contentType: u.originalMime,
    );
    await _storage.upload(
      Buckets.productMedia,
      paths.catalogue,
      Uint8List.fromList(u.catalogue),
      contentType: 'image/jpeg',
    );
    await _storage.upload(Buckets.productMedia, paths.share, Uint8List.fromList(u.share), contentType: 'image/jpeg');
    await _storage.upload(Buckets.productMedia, paths.thumb, Uint8List.fromList(u.thumb), contentType: 'image/jpeg');
    // The row is written last: a photo becomes visible only when every
    // derivative exists. Orphaned objects from a failed attempt are removed
    // by the storage cleanup job.
    await _api.run(
      'product_media.insert',
      () => _client.from('product_media').insert({
        'product_id': productId,
        'kind': 'image',
        'status': 'ready',
        'mime_type': u.originalMime,
        'original_path': paths.original,
        'catalogue_path': paths.catalogue,
        'share_path': paths.share,
        'thumb_path': paths.thumb,
        'width': u.width,
        'height': u.height,
        'bytes': u.original.length,
        'sha256': u.sha256,
        'sort_order': u.sortOrder,
      }),
    );
  }

  Future<void> archivePhoto(String photoId) => _api.run('product_media.archive', () async {
    final rows = await _client
        .from('product_media')
        .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', photoId)
        .select('id');
    if (rows.isEmpty) throw const AppFailure(FailureKind.permissionDenied);
  });
}
