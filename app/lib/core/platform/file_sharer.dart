import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// A file to hand to another app (WhatsApp, Files, …).
@immutable
class ShareFile {
  const ShareFile({required this.bytes, required this.name, required this.mimeType});

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

/// Opens the system share sheet. Only share-safe content may be passed in:
/// callers build it from the server's allow-listed share payloads.
abstract interface class FileSharer {
  /// False when sharing is not possible on this device.
  Future<bool> share({List<ShareFile> files, String? text});
}

class SystemFileSharer implements FileSharer {
  const SystemFileSharer();

  @override
  Future<bool> share({List<ShareFile> files = const [], String? text}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [for (final f in files) XFile.fromData(f.bytes, name: f.name, mimeType: f.mimeType)],
          fileNameOverrides: files.isEmpty ? null : [for (final f in files) f.name],
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }
}

final fileSharerProvider = Provider<FileSharer>((ref) => const SystemFileSharer());
