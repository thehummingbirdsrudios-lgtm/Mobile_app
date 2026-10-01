import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/storage_client.dart';
import '../../../../core/util/ids.dart';
import '../../domain/remarks.dart';

/// Remarks: RLS-protected table (tenant-wide read, column-level insert
/// grants) and the private `remarks` bucket under the tenant folder.
class RemarksApi {
  const RemarksApi(this._client, this._api, this._storage);

  final SupabaseClient _client;
  final ApiClient _api;
  final StorageClient _storage;

  Future<List<Remark>> list(RemarkTarget target, {required int limit}) => _api.run('remarks.list', () async {
    final rows = await _client
        .from('remarks')
        .select('id,kind,text_body,media_path,duration_ms,created_at,created_by')
        .eq(target.kind.column, target.id)
        .isFilter('archived_at', null)
        .order('created_at', ascending: false)
        .limit(limit);
    final authorIds = {for (final r in rows) ?r['created_by'] as String?};
    final names = <String, String>{};
    if (authorIds.isNotEmpty) {
      // RLS only returns colleagues from the same business.
      for (final u in await _client.from('app_users').select('id,display_name').inFilter('id', authorIds.toList())) {
        names[u.requireString('id')] = u.requireString('display_name');
      }
    }
    return [
      for (final r in rows)
        Remark(
          id: r.requireString('id'),
          kind: RemarkKind.parse(r.requireString('kind')),
          createdAt: r.requireDateTime('created_at'),
          text: r.optionalString('text_body'),
          mediaPath: r.optionalString('media_path'),
          duration: switch (r.optionalInt('duration_ms')) {
            final ms? => Duration(milliseconds: ms),
            null => null,
          },
          authorId: r.optionalString('created_by'),
          authorName: names[r['created_by']],
        ),
    ];
  });

  Future<void> insert(RemarkTarget target, Map<String, Object?> columns) => _api.run(
    'remarks.insert',
    () async => _client.from('remarks').insert({target.kind.column: target.id, ...columns}),
  );

  /// Uploads media to `{tenant}/remarks/{uuid}.{ext}` and returns the key.
  Future<String> upload(String tenantId, Uint8List bytes, {required String ext, required String mimeType}) async {
    final path = '$tenantId/remarks/${newUuid()}.$ext';
    await _storage.upload(Buckets.remarks, path, bytes, contentType: mimeType);
    return path;
  }

  Future<void> archive(String remarkId) => _api.run('remarks.archive', () async {
    final rows = await _client
        .from('remarks')
        .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', remarkId)
        .select('id');
    if (rows.isEmpty) throw const AppFailure(FailureKind.permissionDenied);
  });
}
