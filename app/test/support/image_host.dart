import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/core/core.dart';

/// Distinct, easily recognisable colour for product [n].
img.ColorRgb8 productColor(int n) => img.ColorRgb8((n * 67) % 200 + 40, (n * 131) % 200 + 40, (n * 29) % 200 + 40);

Uint8List solidJpeg(int n, {int width = 600, int height = 600}) {
  final image = img.Image(width: width, height: height)..clear(productColor(n));
  return img.encodeJpg(image, quality: 92);
}

/// A fake image host. Paths decide the behaviour:
///  /p/{n}.jpg      600×600 JPEG in productColor(n)
///  /wide/{n}.jpg   600×300 JPEG (aspect ratio check)
///  /png/{n}.png    PNG with transparency
///  /webp/x.webp    real WebP (fixture)
///  /large/x.jpg    4000×3000 JPEG
///  /huge/x.jpg     declares more bytes than allowed
///  /broken/x.jpg   bytes that are not an image
///  /missing/x.jpg  404
///  /slow/x.jpg     never answers
///  /flaky/{n}.jpg  503 once, then the photo
///  /redirect/x.jpg 302 elsewhere
///  /html/x.jpg     text/html body
class FakeImageHost {
  FakeImageHost() {
    client = MockClient.streaming((request, _) async {
      final path = request.url.path;
      requests[path] = (requests[path] ?? 0) + 1;
      inFlight++;
      maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
      try {
        if (offline) throw http.ClientException('offline');
        await Future<void>.delayed(Duration.zero);
        return await _respond(path, request);
      } finally {
        inFlight--;
      }
    });
  }

  late final http.Client client;
  final requests = <String, int>{};
  int inFlight = 0;
  int maxInFlight = 0;
  bool offline = false;
  final _slow = Completer<http.StreamedResponse>();

  static final _large = img.encodeJpg(img.Image(width: 4000, height: 3000)..clear(img.ColorRgb8(200, 160, 60)));

  int get totalRequests => requests.values.fold(0, (a, b) => a + b);

  http.StreamedResponse _ok(List<int> body, String type) =>
      http.StreamedResponse(Stream.value(body), 200, contentLength: body.length, headers: {'content-type': type});

  Future<http.StreamedResponse> _respond(String path, http.BaseRequest request) async {
    final n = int.tryParse(RegExp(r'(\d+)').firstMatch(path.split('/').last)?.group(1) ?? '') ?? 0;
    switch (path.split('/')[1]) {
      case 'p':
        return _ok(solidJpeg(n), 'image/jpeg');
      case 'wide':
        return _ok(solidJpeg(n, height: 300), 'image/jpeg');
      case 'png':
        final image = img.Image(width: 500, height: 500, numChannels: 4)..clear(img.ColorRgba8(0, 0, 0, 0));
        img.fillCircle(image, x: 250, y: 250, radius: 200, color: img.ColorRgba8(30, 90, 200, 255));
        return _ok(img.encodePng(image), 'image/png');
      case 'webp':
        return _ok(File('test/fixtures/images/product.webp').readAsBytesSync(), 'image/webp');
      case 'large':
        return _ok(_large, 'image/jpeg');
      case 'huge':
        return http.StreamedResponse(
          Stream.value(List.filled(10, 0)),
          200,
          contentLength: 50 * 1024 * 1024,
          headers: {'content-type': 'image/jpeg'},
        );
      case 'broken':
        return _ok(List.generate(4096, (i) => (i * 7) % 256), 'image/jpeg');
      case 'missing':
        return http.StreamedResponse(const Stream.empty(), 404);
      case 'slow':
        return _slow.future;
      case 'flaky':
        if (requests[path] == 1) return http.StreamedResponse(const Stream.empty(), 503);
        return _ok(solidJpeg(n), 'image/jpeg');
      case 'redirect':
        return http.StreamedResponse(const Stream.empty(), 302, headers: {'location': 'https://evil.test/x.jpg'});
      case 'html':
        return _ok('<html>not an image</html>'.codeUnits, 'text/html');
    }
    return http.StreamedResponse(const Stream.empty(), 404);
  }
}

/// Stored keys resolve to this fake host (as signed URLs would).
class FakeImageSource implements ImageSourceService {
  @override
  Future<Uri> resolve(ImageRef ref) async => Uri.https('storage.test', '/${ref.path}');
}

class SilentSink implements LogSink {
  final events = <LogEvent>[];

  @override
  void write(LogEvent event) => events.add(event);
}

/// A loader wired to [host] with fast timeouts, real validation and real
/// optimisation (run inline: no isolates needed in tests).
OptimizedImageLoader loaderFor(
  FakeImageHost host, {
  ImageCacheService? cache,
  SilentSink? sink,
  Duration timeout = const Duration(milliseconds: 200),
}) => OptimizedImageLoader(
  source: FakeImageSource(),
  fetcher: ImageFetchService(
    host.client,
    policy: ImageFetchPolicy(allowedHosts: {'storage.test'}, timeout: timeout, maxBytes: 8 * 1024 * 1024),
    delay: (_) async {},
  ),
  cache: cache ?? MemoryImageCache(maxBytes: 64 * 1024 * 1024),
  logger: AppLogger(minLevel: LogLevel.debug, sinks: [sink ?? SilentSink()]),
  optimizer: ImageOptimizationService(runner: (job) async => optimizeImage(job)),
);
