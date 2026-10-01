import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/app/app.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/dashboard/dashboard.dart';
import 'package:vepari/features/settings/settings.dart';

import 'fakes.dart';

const testConfig = AppConfig(
  environment: 'test',
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'test-key',
  loginDomain: 'login.vepari.invalid',
  appVersion: '0.1.0',
);

/// Pumps the full app with fakes at a given screen size and language.
Future<ProviderContainer> pumpVepari(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeDashboardRepository? dashboard,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  AppConfig config = testConfig,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = MemoryPreferenceStore()..values['locale'] = locale.languageCode;
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      preferenceStoreProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth),
      dashboardRepositoryProvider.overrideWithValue(dashboard ?? FakeDashboardRepository(summary: sampleSummary)),
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
