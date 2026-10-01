import 'dart:typed_data';

import '../../domain/remarks.dart';
import '../remote/remarks_api.dart';

class RemarksRepositoryImpl implements RemarksRepository {
  const RemarksRepositoryImpl(this._remote);

  final RemarksApi _remote;

  @override
  Future<List<Remark>> list(RemarkTarget target, {int limit = 50}) => _remote.list(target, limit: limit);

  @override
  Future<void> addText(RemarkTarget target, String text) =>
      _remote.insert(target, {'kind': 'text', 'text_body': text.trim()});

  @override
  Future<void> addVoice(
    RemarkTarget target, {
    required String tenantId,
    required Uint8List audio,
    required String mimeType,
    required Duration duration,
  }) async {
    final path = await _remote.upload(tenantId, audio, ext: 'm4a', mimeType: mimeType);
    await _remote.insert(target, {'kind': 'voice', 'media_path': path, 'duration_ms': duration.inMilliseconds});
  }

  @override
  Future<void> addPhoto(RemarkTarget target, {required String tenantId, required Uint8List jpeg}) async {
    final path = await _remote.upload(tenantId, jpeg, ext: 'jpg', mimeType: 'image/jpeg');
    await _remote.insert(target, {'kind': 'photo', 'media_path': path});
  }

  @override
  Future<void> archive(String remarkId) => _remote.archive(remarkId);
}
