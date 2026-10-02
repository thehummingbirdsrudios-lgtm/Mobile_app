import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vepari/core/core.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('vepari-share-test'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<Directory> tempRoot() async => root;
  Directory folder() => Directory('${root.path}/vepari-share');
  List<FileSystemEntity> leftovers() => folder().existsSync() ? folder().listSync(recursive: true) : const [];

  final bill = ShareFile(bytes: _pdf, name: 'bill-1045.pdf', mimeType: 'application/pdf');

  test('the file exists while the sheet is open and is deleted afterwards', () async {
    late List<XFile> sharedFiles;
    late Uint8List seenBytes;
    final sharer = SystemFileSharer(
      tempRoot: tempRoot,
      platformShare: (params) async {
        sharedFiles = params.files!;
        seenBytes = await File(sharedFiles.single.path).readAsBytes();
      },
    );
    expect(await sharer.share(files: [bill], text: 'Bill'), isTrue);
    expect(sharedFiles.single.path, endsWith('/bill-1045.pdf'));
    expect(sharedFiles.single.mimeType, 'application/pdf');
    expect(seenBytes, _pdf);
    expect(leftovers().whereType<File>(), isEmpty);
  });

  test('a failed share reports false and still cleans up', () async {
    final sharer = SystemFileSharer(tempRoot: tempRoot, platformShare: (_) async => throw StateError('no sheet'));
    expect(await sharer.share(files: [bill]), isFalse);
    expect(leftovers().whereType<File>(), isEmpty);
  });

  test('odd file names cannot escape the share folder', () async {
    String? path;
    final sharer = SystemFileSharer(tempRoot: tempRoot, platformShare: (p) async => path = p.files!.single.path);
    await sharer.share(
      files: [ShareFile(bytes: _pdf, name: '../../etc/passwd', mimeType: 'text/plain')],
    );
    expect(path, startsWith('${folder().path}/'));
    expect(path, isNot(contains('..')));
  });

  test('start-up sweep removes leftovers from an interrupted share', () async {
    final stale = File('${folder().path}/x/bill.pdf')..createSync(recursive: true);
    await SystemFileSharer(tempRoot: tempRoot).sweep();
    expect(stale.existsSync(), isFalse);
    // Nothing to sweep is fine too.
    await SystemFileSharer(tempRoot: tempRoot).sweep();
  });
}

final _pdf = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
