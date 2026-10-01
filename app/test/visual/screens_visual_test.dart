// Opt-in visual review renders (real fonts, fake data). Not a golden gate:
// font rasterisation differs across platforms, so output is for human review.
//   VEPARI_SCREENSHOTS=1 flutter test test/visual --update-goldens
// Images land in test/visual/goldens/ (gitignored).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/app/app.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  const weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
  await family('HindVadodara', [for (final w in weights) 'HindVadodara-$w.ttf']);
  await family('Hind', [for (final w in weights) 'Hind-$w.ttf']);
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final enabled = Platform.environment['VEPARI_SCREENSHOTS'] == '1';

  setUpAll(() async {
    if (enabled) await _loadFonts();
  });

  for (final lang in ['gu', 'hi', 'en']) {
    for (final (label, size) in [('phone', const Size(360, 780)), ('tablet', const Size(1024, 768))]) {
      testWidgets('home $lang $label', (tester) async {
        await pumpVepari(
          tester,
          auth: FakeAuthRepository(restored: ownerSession),
          locale: Locale(lang),
          size: size,
        );
        await expectLater(find.byType(VepariApp), matchesGoldenFile('goldens/home-$lang-$label.png'));

        // The More destination (same icon in the bottom bar and the rail).
        await tester.tap(find.byIcon(Icons.menu_rounded).first);
        await tester.pumpAndSettle();
        await expectLater(find.byType(VepariApp), matchesGoldenFile('goldens/more-$lang-$label.png'));
      }, skip: !enabled);
    }
  }

  testWidgets('home loading skeleton (phone, gu)', (tester) async {
    final dashboard = FakeDashboardRepository(summary: sampleSummary)..gate = true;
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      dashboard: dashboard,
      locale: const Locale('gu'),
      size: const Size(360, 780),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 700));
    await expectLater(find.byType(VepariApp), matchesGoldenFile('goldens/home-loading-gu-phone.png'));
    dashboard.release();
    await tester.pumpAndSettle();
  }, skip: !enabled);
}
