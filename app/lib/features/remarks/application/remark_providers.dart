import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/remarks.dart';

/// Overridden at the composition root and in tests.
final remarksRepositoryProvider = Provider<RemarksRepository>(
  (ref) => throw UnimplementedError('remarksRepositoryProvider must be overridden'),
);

final remarksProvider = FutureProvider.autoDispose.family<List<Remark>, RemarkTarget>((ref, target) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(remarksRepositoryProvider).list(target);
});

final remarkWriterProvider = Provider<RemarkWriter>(RemarkWriter.new);

class RemarkWriter {
  RemarkWriter(this._ref);

  final Ref _ref;

  RemarksRepository get _repo => _ref.read(remarksRepositoryProvider);

  String get _tenant {
    final tenantId = _ref.read(currentSessionProvider)?.tenantId;
    if (tenantId == null) throw const AppFailure(FailureKind.sessionExpired);
    return tenantId;
  }

  Future<void> addText(RemarkTarget target, String text) async {
    await _repo.addText(target, text);
    _ref.invalidate(remarksProvider(target));
  }

  Future<void> addVoice(RemarkTarget target, RecordedAudio audio) async {
    await _repo.addVoice(
      target,
      tenantId: _tenant,
      audio: audio.bytes,
      mimeType: audio.mimeType,
      duration: audio.duration,
    );
    _ref.invalidate(remarksProvider(target));
  }

  /// Photos are stored as the 1280px share-size JPEG (no original, no EXIF).
  Future<void> addPhoto(RemarkTarget target, Uint8List picked) async {
    final tenantId = _tenant;
    final derived = await _ref.read(imageProcessorProvider)(picked);
    await _repo.addPhoto(target, tenantId: tenantId, jpeg: derived.share);
    _ref.invalidate(remarksProvider(target));
  }

  Future<void> archive(RemarkTarget target, String remarkId) async {
    await _repo.archive(remarkId);
    _ref.invalidate(remarksProvider(target));
  }
}
