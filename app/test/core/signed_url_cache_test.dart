import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';

class _CountingStorage implements StorageClient {
  int calls = 0;
  Completer<void>? gate;

  @override
  Future<String> signedUrl(String bucket, String path, {Duration expiresIn = const Duration(hours: 1)}) async {
    calls++;
    if (gate != null) await gate!.future;
    return 'https://storage.invalid/$bucket/$path?v=$calls';
  }

  @override
  Future<void> upload(String bucket, String path, Uint8List bytes, {required String contentType}) async {}

  @override
  Future<Uint8List> download(String bucket, String path) async => Uint8List(0);
}

void main() {
  test('resolves (regression: the in-flight cleanup once deadlocked every request)', () async {
    final cache = SignedUrlCache(_CountingStorage());
    expect(
      await cache.get((bucket: 'product-media', path: 't/a.jpg')).timeout(const Duration(seconds: 1)),
      'https://storage.invalid/product-media/t/a.jpg?v=1',
    );
  });

  test('concurrent requests for one object share a single signing call', () async {
    final storage = _CountingStorage()..gate = Completer<void>();
    final cache = SignedUrlCache(storage);
    final a = cache.get((bucket: 'b', path: 'p'));
    final b = cache.get((bucket: 'b', path: 'p'));
    storage.gate!.complete();
    expect(await a, await b);
    expect(storage.calls, 1);
  });

  test('reuses a URL for 45 minutes, then signs again', () async {
    var now = DateTime.utc(2026, 10, 1, 10);
    final storage = _CountingStorage();
    final cache = SignedUrlCache(storage, clock: () => now);
    await cache.get((bucket: 'b', path: 'p'));
    now = now.add(const Duration(minutes: 44));
    await cache.get((bucket: 'b', path: 'p'));
    expect(storage.calls, 1);
    now = now.add(const Duration(minutes: 2));
    await cache.get((bucket: 'b', path: 'p'));
    expect(storage.calls, 2);
  });

  test('a failed signing is not cached', () async {
    final storage = _FailingOnce();
    final cache = SignedUrlCache(storage);
    await expectLater(cache.get((bucket: 'b', path: 'p')), throwsA(isA<AppFailure>()));
    expect(await cache.get((bucket: 'b', path: 'p')), 'ok');
  });
}

class _FailingOnce extends _CountingStorage {
  @override
  Future<String> signedUrl(String bucket, String path, {Duration expiresIn = const Duration(hours: 1)}) async {
    calls++;
    if (calls == 1) throw const AppFailure(FailureKind.network);
    return 'ok';
  }
}
