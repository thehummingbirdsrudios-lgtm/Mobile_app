import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../util/ids.dart';

/// A file to hand to another app (WhatsApp, Files, …).
@immutable
class ShareFile {
  const ShareFile({required this.bytes, required this.name, required this.mimeType});

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

/// Opens the system share sheet. Only share-safe content may be passed in:
/// callers build it from the server's allow-listed share payloads — the one
/// exception is the owner's own data export (owner-only on the server).
abstract interface class FileSharer {
  /// False when sharing is not possible on this device.
  Future<bool> share({List<ShareFile> files, String? text});
}

typedef PlatformShare = Future<void> Function(ShareParams params);

Future<void> _systemShare(ShareParams params) async => SharePlus.instance.share(params);

/// share_plus would write in-memory files to a new temp folder per share and
/// never delete them — bills, receipts and the owner's export (with cost
/// prices) would pile up on the phone. Instead each file is written to one
/// app folder and deleted as soon as the share sheet returns (on Android
/// share_plus hands other apps its own copy first), and leftovers from a
/// crash are swept at start-up.
class SystemFileSharer implements FileSharer {
  const SystemFileSharer({this._platformShare = _systemShare, this._tempRoot});

  final PlatformShare _platformShare;
  final Future<Directory> Function()? _tempRoot;

  static const _folderName = 'vepari-share';

  Future<Directory> _folder() async => Directory('${(await (_tempRoot ?? getTemporaryDirectory)()).path}/$_folderName');

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_').replaceAll(RegExp(r'\.{2,}'), '.');
    return cleaned.isEmpty || cleaned.startsWith('.') ? 'file$cleaned' : cleaned;
  }

  @override
  Future<bool> share({List<ShareFile> files = const [], String? text}) async {
    if (kIsWeb) return _shareInMemory(files, text);
    final written = <File>[];
    try {
      if (files.isNotEmpty) {
        final folder = await (await _folder()).create(recursive: true);
        for (final f in files) {
          // A unique sub-folder keeps the readable file name for the receiver.
          final dir = await Directory('${folder.path}/${newUuid()}').create();
          final file = File('${dir.path}/${_safeName(f.name)}');
          await file.writeAsBytes(f.bytes, flush: true);
          written.add(file);
        }
      }
      await _platformShare(
        ShareParams(
          text: text,
          files: [for (var i = 0; i < written.length; i++) XFile(written[i].path, mimeType: files[i].mimeType)],
        ),
      );
      return true;
    } on Object {
      return false;
    } finally {
      for (final file in written) {
        try {
          await file.parent.delete(recursive: true);
        } on Object {
          // Swept at the next start-up.
        }
      }
    }
  }

  Future<bool> _shareInMemory(List<ShareFile> files, String? text) async {
    try {
      await _platformShare(
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

  /// Deletes anything left from an interrupted share. Never throws.
  Future<void> sweep() async {
    if (kIsWeb) return;
    try {
      final folder = await _folder();
      if (folder.existsSync()) await folder.delete(recursive: true);
    } on Object {
      // Best effort.
    }
  }
}

final fileSharerProvider = Provider<FileSharer>((ref) => const SystemFileSharer());
