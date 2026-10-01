import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/core/core.dart';

Uint8List _jpeg(int w, int h) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(180, 140, 60));
  img.fillCircle(image, x: w ~/ 2, y: h ~/ 2, radius: w ~/ 6, color: img.ColorRgb8(200, 20, 40));
  return img.encodeJpg(image, quality: 92);
}

void main() {
  test('builds catalogue/share/thumb derivatives at the right sizes', () {
    final d = processImage(_jpeg(3000, 2000));
    expect(d.originalMime, 'image/jpeg');
    expect(d.width, 3000);
    expect(d.height, 2000);
    expect(img.decodeJpg(d.catalogue)!.width, ImageLimits.catalogueEdge);
    expect(img.decodeJpg(d.share)!.width, ImageLimits.shareEdge);
    expect(img.decodeJpg(d.thumb)!.width, ImageLimits.thumbEdge);
    expect(d.thumb.lengthInBytes, lessThan(d.catalogue.lengthInBytes));
    expect(d.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('portrait images are bounded by height', () {
    final d = processImage(_jpeg(1000, 2400));
    expect(img.decodeJpg(d.thumb)!.height, ImageLimits.thumbEdge);
  });

  test('small images are never upscaled', () {
    final d = processImage(_jpeg(200, 150));
    expect(img.decodeJpg(d.catalogue)!.width, 200);
  });

  test('PNG is accepted and re-encoded as JPEG derivatives', () {
    final png = img.encodePng(img.Image(width: 500, height: 500));
    final d = processImage(png);
    expect(d.originalMime, 'image/png');
    expect(img.decodeJpg(d.thumb), isNotNull);
  });

  test('rejects non-images and renamed files by content, not by name', () {
    expect(
      () => processImage(Uint8List.fromList(List.filled(1000, 7))),
      throwsA(isA<ImageRejectedException>().having((e) => e.reason, 'reason', ImageRejection.notAnImage)),
    );
    expect(() => processImage(Uint8List.fromList('%PDF-1.7 fake'.codeUnits)), throwsA(isA<ImageRejectedException>()));
  });

  test('rejects oversized uploads before decoding', () {
    expect(
      () => processImage(Uint8List(ImageLimits.maxBytes + 1)),
      throwsA(isA<ImageRejectedException>().having((e) => e.reason, 'reason', ImageRejection.tooLarge)),
    );
  });

  test('identical bytes give identical hashes (dedupe)', () {
    final bytes = _jpeg(400, 400);
    expect(processImage(bytes).sha256, processImage(bytes).sha256);
  });
}
