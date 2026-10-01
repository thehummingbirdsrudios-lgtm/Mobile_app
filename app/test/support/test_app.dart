import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/app/app.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/bills/bills.dart';
import 'package:vepari/features/catalogue/catalogue.dart';
import 'package:vepari/features/customers/customers.dart';
import 'package:vepari/features/dashboard/dashboard.dart';
import 'package:vepari/features/hisaab/hisaab.dart';
import 'package:vepari/features/orders/orders.dart';
import 'package:vepari/features/search/search.dart';
import 'package:vepari/features/settings/settings.dart';

import 'fakes.dart';

const testConfig = AppConfig(
  environment: 'test',
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'test-key',
  loginDomain: 'login.vepari.invalid',
  appVersion: '0.1.0',
);

/// Renders images as plain boxes in tests (no network).
Widget testImageBuilder({
  required String url,
  required String cacheKey,
  required BoxFit fit,
  int? cacheWidth,
  String? semanticLabel,
}) => ColoredBox(key: ValueKey('img:$cacheKey'), color: const Color(0xFFE0D6C4));

/// A real 2×2 PNG (fake time cannot await a real raster capture).
Future<Uint8List> fakeCapture(GlobalKey key, {double pixelRatio = 1}) async =>
    img.encodePng(img.Image(width: 2, height: 3));

/// Pumps the full app with fakes at a given screen size and language.
Future<ProviderContainer> pumpVepari(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeDashboardRepository? dashboard,
  FakeCatalogueRepository? catalogue,
  FakePhotoPicker? photos,
  FakeSearchRepository? search,
  FakeCustomerRepository? customers,
  FakeContactLauncher? contacts,
  FakeOrdersRepository? orders,
  MemoryCartStore? carts,
  FakeHisaabRepository? hisaab,
  FakeBillsRepository? bills,
  FakeFileSharer? sharer,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  AppConfig config = testConfig,
  bool settle = true,
  List<Override> extraOverrides = const [],

  /// False when [extraOverrides] supplies its own product/customer actions.
  bool crossModule = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = MemoryPreferenceStore()..values['locale'] = locale.languageCode;
  final container = ProviderContainer(
    overrides: [
      if (crossModule) ...appLayerOverrides else navigatorOverride,
      storageClientProvider.overrideWithValue(FakeStorage()),
      networkImageBuilderProvider.overrideWithValue(testImageBuilder),
      catalogueRepositoryProvider.overrideWithValue(catalogue ?? FakeCatalogueRepository()),
      photoPickerProvider.overrideWithValue(photos ?? FakePhotoPicker()),
      searchRepositoryProvider.overrideWithValue(search ?? FakeSearchRepository()),
      customerRepositoryProvider.overrideWithValue(customers ?? FakeCustomerRepository()),
      contactLauncherProvider.overrideWithValue(contacts ?? FakeContactLauncher()),
      ordersRepositoryProvider.overrideWithValue(orders ?? FakeOrdersRepository()),
      cartStoreProvider.overrideWithValue(carts ?? MemoryCartStore()),
      hisaabRepositoryProvider.overrideWithValue(hisaab ?? FakeHisaabRepository()),
      billsRepositoryProvider.overrideWithValue(bills ?? FakeBillsRepository()),
      fileSharerProvider.overrideWithValue(sharer ?? FakeFileSharer()),
      widgetCapturerProvider.overrideWithValue(fakeCapture),
      pdfBuilderProvider.overrideWithValue(renderImagePdf),
      imageProcessorProvider.overrideWithValue((bytes) async => processImage(bytes)),
      appConfigProvider.overrideWithValue(config),
      preferenceStoreProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth),
      dashboardRepositoryProvider.overrideWithValue(dashboard ?? FakeDashboardRepository(summary: sampleSummary)),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const VepariApp()));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return container;
}
