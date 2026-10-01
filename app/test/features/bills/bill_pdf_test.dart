import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/core/core.dart';
import 'package:vepari/features/bills/application/pdf/bill_pdf_layout.dart';
import 'package:vepari/features/bills/application/pdf/bill_pdf_renderer.dart';
import 'package:vepari/features/bills/application/pdf/bill_pdf_service.dart';
import 'package:vepari/features/bills/application/pdf/pdf_image_embedding_service.dart';
import 'package:vepari/features/bills/bills.dart';

import '../../support/image_host.dart';
import '../../support/pdf_inspector.dart';

const labels = BillPdfLabels(
  title: 'BILL',
  billNo: 'Bill #12',
  date: '01 Oct 2026',
  orderRef: 'Order #1045',
  billTo: 'Bill to',
  colPhoto: 'Photo',
  colDesign: 'Design no.',
  colItem: 'Product / item',
  colQty: 'Qty',
  colRate: 'Rate',
  colAmount: 'Amount',
  totalQty: 'Pieces',
  totalWeight: 'Total weight',
  total: 'Total',
  paid: 'Paid with this order',
  bakiAfter: 'Baki after this bill',
  advance: 'Advance',
  continued: 'continued',
);

BillItem item(int n, String? path, {String? name}) => BillItem(
  designNo: 'D-${n.toString().padLeft(3, '0')}',
  name: name ?? 'Kundan necklace set $n',
  qty: n % 5 + 1,
  rate: Money.paise(25000 + n * 100),
  amount: Money.paise((25000 + n * 100) * (n % 5 + 1)),
  weightMg: 12000 + n,
  imagePath: path,
);

BillDocument bill(List<BillItem> items, {String customer = 'Patel Kundan Stores', String business = 'Shree Jewels'}) =>
    BillDocument(
      billNo: 12,
      issuedAt: DateTime.utc(2026, 10),
      orderNo: 1045,
      customerName: customer,
      customerPhone: '9825012345',
      business: BillBusiness(
        name: business,
        address: 'Soni Bazar, Rajkot',
        gstin: '24ABCDE1234F1Z5',
        footer: 'Thank you',
      ),
      totalQty: items.fold(0, (s, i) => s + i.qty),
      total: items.fold(Money.zero, (s, i) => s + i.amount),
      paid: Money.zero,
      balanceAfter: const Money.paise(1500000),
      items: items,
    );

Future<({Uint8List regular, Uint8List bold})> fileFonts() async => (
  regular: File('assets/fonts/Hind-Regular.ttf').readAsBytesSync(),
  bold: File('assets/fonts/Hind-SemiBold.ttf').readAsBytesSync(),
);

Future<RasterText> noShaping(
  String text, {
  required double fontSize,
  bool bold = false,
  double maxWidth = 0,
  int maxLines = 2,
}) => throw StateError('Latin-only bill must not need shaping: $text');

BillPdfService service(FakeImageHost host, {ImageCacheService? cache, SilentSink? sink, TextRasterizer? shaper}) =>
    BillPdfService(
      images: PdfImageEmbeddingService(loaderFor(host, cache: cache, sink: sink)),
      shaper: shaper ?? noShaping,
      fonts: fileFonts,
      renderer: renderBillPdf,
    );

/// Centre colour of an embedded JPEG is the product's colour (± JPEG error).
bool showsProduct(Uint8List jpeg, int n) {
  final decoded = img.decodeJpg(jpeg)!;
  final p = decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2);
  final c = productColor(n);
  return (p.r - c.r).abs() < 14 && (p.g - c.g).abs() < 14 && (p.b - c.b).abs() < 14;
}

void main() {
  test('tiers by line count', () {
    expect(BillImageTier.forCount(1), BillImageTier.standard);
    expect(BillImageTier.forCount(15), BillImageTier.standard);
    expect(BillImageTier.forCount(16), BillImageTier.compact);
    expect(BillImageTier.forCount(20), BillImageTier.compact);
    expect(BillImageTier.forCount(21), BillImageTier.dense);
    expect(BillImageTier.forCount(500), BillImageTier.dense);
    for (final tier in BillImageTier.values) {
      // ≥ 5 px per point (≈ 360 dpi): sharp when zoomed or printed.
      expect(tier.spec.maxEdgePx / tier.boxPt, greaterThanOrEqualTo(5));
      expect(tier.spec.jpegQuality, greaterThanOrEqualTo(85));
    }
  });

  group('every line gets its own photo, at any size of bill', () {
    for (final n in [1, 5, 15, 16, 20, 21, 30, 50, 100]) {
      test('$n products', () async {
        final host = FakeImageHost();
        final items = [for (var i = 1; i <= n; i++) item(i, 'p/$i.jpg')];
        final result = await service(host).generate(bill(items), labels);
        final pdf = PdfInspection(result.bytes);
        final tier = BillImageTier.forCount(n);

        expect(pdf.isPdf, isTrue);
        expect(result.photos, n);
        expect(result.placeholders, 0);
        expect(pdf.images.length, n);
        // Drawn in row order across all pages, each row showing ITS product.
        final drawn = pdf.imagesDrawn;
        expect(drawn.length, n);
        for (var row = 0; row < n; row++) {
          expect(showsProduct(pdf.images[drawn[row]]!.data, row + 1), isTrue, reason: 'row ${row + 1}');
        }
        for (final image in pdf.images.values) {
          expect(image.filter, 'DCTDecode'); // compact JPEG, embedded (not a link)
          expect(image.width, tier.spec.maxEdgePx); // resized to the cell, not the 600px source
          expect(image.data.length, lessThan(40 * 1024));
        }
        // Small enough for WhatsApp/email.
        expect(pdf.size, lessThan(300 * 1024 + n * 30 * 1024));
        expect(pdf.pages.length, n <= 8 ? 1 : greaterThan(1));
        // Bounded downloads; each photo fetched once.
        expect(host.maxInFlight, lessThanOrEqualTo(3));
        expect(host.totalRequests, n);
        // Nothing points back to the network.
        expect(String.fromCharCodes(result.bytes), isNot(contains('storage.test')));
      });
    }
  });

  group('image sources', () {
    Future<(BillPdf, PdfInspection, FakeImageHost, SilentSink)> one(List<BillItem> items) async {
      final host = FakeImageHost();
      final sink = SilentSink();
      final result = await service(host, sink: sink).generate(bill(items), labels);
      return (result, PdfInspection(result.bytes), host, sink);
    }

    test('PNG with transparency becomes a JPEG on white', () async {
      final (r, pdf, _, _) = await one([item(1, 'png/1.png')]);
      expect(r.photos, 1);
      final image = pdf.images.values.single;
      expect(image.filter, 'DCTDecode');
      final corner = img.decodeJpg(image.data)!.getPixel(2, 2);
      expect(corner.r, greaterThan(240)); // transparent → white, not black
    });

    test('WebP is decoded and embedded', () async {
      final (r, pdf, _, _) = await one([item(1, 'webp/1.webp')]);
      expect(r.photos, 1);
      expect(pdf.images.values.single.width, 360);
      expect(pdf.images.values.single.height, 240); // 600×400 keeps its aspect ratio
    });

    test('a 4000×3000 photo is reduced to the cell size, aspect kept', () async {
      final (_, pdf, _, _) = await one([item(1, 'large/1.jpg')]);
      final image = pdf.images.values.single;
      expect((image.width, image.height), (360, 270));
    });

    test('non-square photo keeps its proportions', () async {
      final (_, pdf, _, _) = await one([item(1, 'wide/1.jpg')]);
      final image = pdf.images.values.single;
      expect((image.width, image.height), (360, 180));
    });

    test('broken, 404, slow, oversized, redirected and non-image URLs never break the bill', () async {
      final items = [
        item(1, 'p/1.jpg'),
        item(2, 'broken/2.jpg'),
        item(3, 'missing/3.jpg'),
        item(4, 'slow/4.jpg'),
        item(5, 'huge/5.jpg'),
        item(6, 'redirect/6.jpg'),
        item(7, 'html/7.jpg'),
        item(8, null), // no photo stored
        item(9, 'p/9.jpg'),
      ];
      final (r, pdf, host, sink) = await one(items);
      expect(pdf.isPdf, isTrue);
      expect(r.photos, 2);
      expect(r.placeholders, 7);
      final drawn = pdf.imagesDrawn;
      expect(drawn.length, 2);
      expect(showsProduct(pdf.images[drawn[0]]!.data, 1), isTrue);
      expect(showsProduct(pdf.images[drawn[1]]!.data, 9), isTrue);
      // 404 is final (no retry); the slow one timed out and was retried once.
      expect(host.requests['/missing/3.jpg'], 1);
      expect(host.requests['/slow/4.jpg'], 2);
      // Failures are logged with the storage key and design no — never a URL.
      final failures = sink.events.where((e) => e.message == 'image.load_failed').toList();
      expect(
        failures.map((e) => e.fields['label']),
        containsAll(['D-002', 'D-003', 'D-004', 'D-005', 'D-006', 'D-007']),
      );
      expect(failures.firstWhere((e) => e.fields['label'] == 'D-003').fields['reason'], 'notFound:404');
      expect(failures.firstWhere((e) => e.fields['label'] == 'D-005').fields['reason'], 'tooLarge:200');
      expect(failures.firstWhere((e) => e.fields['label'] == 'D-006').fields['reason'], 'redirect:302');
      expect(failures.map((e) => e.fields.toString()).join(), isNot(contains('https://')));
    });

    test('a temporary failure is retried and the photo arrives', () async {
      final (r, _, host, _) = await one([item(1, 'flaky/1.jpg')]);
      expect(r.photos, 1);
      expect(host.requests['/flaky/1.jpg'], 2);
    });

    test('the same photo on many lines is downloaded once and embedded once', () async {
      final (r, pdf, host, _) = await one([item(1, 'p/7.jpg'), item(2, 'p/7.jpg'), item(3, 'p/7.jpg')]);
      expect(host.requests['/p/7.jpg'], 1);
      expect(r.photos, 1);
      expect(pdf.images.length, 1);
      expect(pdf.imagesDrawn.length, 3);
      expect(pdf.imagesDrawn.toSet().length, 1);
    });
  });

  group('cache', () {
    test('a second bill reuses optimised photos — even offline', () async {
      final host = FakeImageHost();
      final cache = MemoryImageCache();
      final items = [for (var i = 1; i <= 5; i++) item(i, 'p/$i.jpg')];
      await service(host, cache: cache).generate(bill(items), labels);
      expect(host.totalRequests, 5);

      host.offline = true;
      final again = await service(host, cache: cache).generate(bill(items), labels);
      expect(host.totalRequests, 5); // nothing downloaded again
      expect(again.photos, 5);
      expect(PdfInspection(again.bytes).imagesDrawn.length, 5);
    });

    test('offline without cache still produces a complete bill with placeholders', () async {
      final host = FakeImageHost()..offline = true;
      final r = await service(host).generate(bill([item(1, 'p/1.jpg'), item(2, 'p/2.jpg')]), labels);
      expect(PdfInspection(r.bytes).isPdf, isTrue);
      expect(r.placeholders, 2);
    });

    test('memory cache is a bounded LRU', () async {
      final cache = MemoryImageCache(maxBytes: 10);
      await cache.write('a', Uint8List(4));
      await cache.write('b', Uint8List(4));
      await cache.read('a'); // a is now most recent
      await cache.write('c', Uint8List(4)); // evicts b
      expect(await cache.read('b'), isNull);
      expect(await cache.read('a'), isNotNull);
      expect(await cache.read('c'), isNotNull);
    });

    test('disk cache stores, evicts least recently used, rejects path-like keys, clears', () async {
      final dir = await Directory.systemTemp.createTemp('vepari-cache');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      final cache = DiskImageCache(() async => dir, maxBytes: 2500);
      final k1 = 'a' * 64;
      final k2 = 'b' * 64;
      final k3 = 'c' * 64;
      await cache.write(k1, Uint8List(1000));
      await File('${dir.path}/$k1.jpg').setLastModified(DateTime(2020));
      await cache.write(k2, Uint8List(1000));
      await cache.write(k3, Uint8List(1000)); // over 2500 → oldest (k1) evicted
      expect(await cache.read(k1), isNull);
      expect(await cache.read(k2), hasLength(1000));
      await cache.write('../../etc/passwd', Uint8List(1));
      expect(File('${dir.path}/../../etc/passwd.jpg').existsSync(), isFalse);
      await cache.clear();
      expect(dir.existsSync(), isFalse);
    });

    test('cache keys depend on the source and the size, never on a URL', () {
      const a = ImageRef(bucket: 'product-media', path: 't/p/1/catalogue.jpg');
      const s1 = ImageSpec(maxEdgePx: 360, jpegQuality: 88);
      const s2 = ImageSpec(maxEdgePx: 240, jpegQuality: 85);
      expect(optimizedImageCacheKey(a, s1), matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(optimizedImageCacheKey(a, s1), isNot(optimizedImageCacheKey(a, s2)));
    });
  });

  group('fetch policy', () {
    ImageFetchService fetcher(FakeImageHost host, {int maxBytes = 8 << 20}) => ImageFetchService(
      host.client,
      policy: ImageFetchPolicy(allowedHosts: {'storage.test'}, maxBytes: maxBytes),
      delay: (_) async {},
    );

    test('only HTTPS on the storage host', () async {
      final host = FakeImageHost();
      for (final url in [
        'http://storage.test/p/1.jpg',
        'https://evil.test/p/1.jpg',
        'https://u:p@storage.test/p/1.jpg',
      ]) {
        await expectLater(
          fetcher(host).fetch(Uri.parse(url)),
          throwsA(isA<ImageFetchException>().having((e) => e.reason, 'reason', ImageFetchFailure.blockedUrl)),
        );
      }
      expect(host.totalRequests, 0);
    });

    test('a body larger than the cap is cut off while streaming', () async {
      final host = FakeImageHost();
      await expectLater(
        fetcher(host, maxBytes: 1000).fetch(Uri.parse('https://storage.test/p/1.jpg')),
        throwsA(isA<ImageFetchException>().having((e) => e.reason, 'reason', ImageFetchFailure.tooLarge)),
      );
    });
  });

  test('validation rejects corrupt and oversized images by content', () {
    const v = ImageValidationService(maxPixels: 1000);
    expect(() => v.validate(Uint8List.fromList(List.filled(100, 3))), throwsA(isA<InvalidImageException>()));
    expect(
      () => v.validate(img.encodePng(img.Image(width: 100, height: 100))),
      throwsA(isA<InvalidImageException>().having((e) => e.reason, 'reason', InvalidImageReason.tooManyPixels)),
    );
    expect(const ImageValidationService().validate(img.encodePng(img.Image(width: 10, height: 5))).width, 10);
  });

  group('Gujarati and Hindi text', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    test('every Indic run is shaped by Flutter; Latin text and numbers stay vector', () async {
      final shaped = <String>[];
      Future<RasterText> recordingShaper(
        String text, {
        required double fontSize,
        bool bold = false,
        double maxWidth = 400,
        int maxLines = 2,
      }) async {
        shaped.add(text);
        return rasterizeText(text, fontSize: fontSize, bold: bold, maxWidth: maxWidth, maxLines: maxLines);
      }

      final host = FakeImageHost();
      final items = [item(1, 'p/1.jpg', name: 'કુંદન સેટ'), item(2, 'p/2.jpg', name: 'झुमका'), item(3, 'p/3.jpg')];
      final document = bill(items, customer: 'પટેલ કુંદન સ્ટોર્સ', business: 'શ્રી જ્વેલ્સ');
      final result = await service(host, shaper: recordingShaper).generate(document, labels);
      expect(shaped, containsAll(['કુંદન સેટ', 'झुमका', 'પટેલ કુંદન સ્ટોર્સ', 'શ્રી જ્વેલ્સ']));
      expect(shaped, isNot(contains('Kundan necklace set 3')));
      expect(shaped.every(needsShaping), isTrue);
      final pdf = PdfInspection(result.bytes);
      // 3 photos (JPEG) + the 4 shaped runs drawn on this one page (business,
      // customer, two item names); the "continued" header is not drawn.
      expect(pdf.images.values.where((i) => i.filter == 'DCTDecode').length, 3);
      expect(pdf.imagesDrawn.length, 3 + 4);
      final runs = billTextRuns(document, labels, const BillPdfLayout(BillImageTier.standard));
      expect(runs.where((r) => needsShaping(r.$2)).map((r) => r.$2).toSet(), shaped.toSet());
    });
  });
}
