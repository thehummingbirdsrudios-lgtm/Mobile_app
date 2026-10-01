import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';

/// Private object storage port (Supabase Storage). Keys always start with the
/// tenant id; the server enforces it (storage RLS), the client never relies
/// on obscurity.
abstract interface class StorageClient {
  /// Short-lived signed URL for displaying a private object.
  Future<String> signedUrl(String bucket, String path, {Duration expiresIn = const Duration(hours: 1)});

  Future<void> upload(String bucket, String path, Uint8List bytes, {required String contentType});

  Future<Uint8List> download(String bucket, String path);
}

class SupabaseStorageClient implements StorageClient {
  SupabaseStorageClient(this._client, this._api);

  final SupabaseClient _client;
  final ApiClient _api;

  @override
  Future<String> signedUrl(String bucket, String path, {Duration expiresIn = const Duration(hours: 1)}) =>
      _api.run('storage.sign', () => _client.storage.from(bucket).createSignedUrl(path, expiresIn.inSeconds));

  @override
  Future<void> upload(String bucket, String path, Uint8List bytes, {required String contentType}) => _api.run(
    'storage.upload',
    () => _client.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, upsert: false)),
    timeout: const Duration(seconds: 60),
  );

  @override
  Future<Uint8List> download(String bucket, String path) => _api.run(
    'storage.download',
    () => _client.storage.from(bucket).download(path),
    timeout: const Duration(seconds: 30),
  );
}

/// Overridden at the composition root.
final storageClientProvider = Provider<StorageClient>(
  (ref) => throw UnimplementedError('storageClientProvider must be overridden'),
);

/// Buckets (mirror supabase/migrations/…0700_storage.sql).
abstract final class Buckets {
  static const productMedia = 'product-media';
  static const remarks = 'remarks';
  static const bills = 'bills';
  static const share = 'share';
  static const branding = 'branding';
}
