import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../features/auth/auth.dart';
import '../features/notifications/notifications.dart';
import '../features/settings/settings.dart';
import '../l10n/app_localizations.dart';
import 'composition.dart';
import 'router.dart';

/// App-layer providers that wire the [AppNavigator] port to go_router.
/// Used by main.dart and by widget tests so both run the same composition.
final appLayerOverrides = [navigatorOverride, ...crossModuleOverrides()];

/// The [AppNavigator] port bound to go_router (tests that replace the
/// cross-module actions use this alone).
final navigatorOverride = appNavigatorProvider.overrideWith((ref) => GoRouterNavigator(ref.watch(routerProvider)));

class VepariApp extends ConsumerWidget {
  const VepariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Identity changed (logout, account switch, revocation): drop every
    // cached image URL and decoded image so nothing from the previous
    // business can be shown, even briefly.
    ref.listen(currentSessionProvider.select((s) => (s?.tenantId, s?.userId)), (previous, next) {
      if (previous == next) return;
      ref.invalidate(signedUrlCacheProvider);
      // Optimised bill photos too (memory and disk).
      unawaited(ref.read(imageCacheServiceProvider).clear());
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      // Disk cache keys are tenant-prefixed storage paths, so another
      // business can never request (or be served) these entries.

      // Push: register this device for the member who just signed in.
      if (next.$2 != null) {
        final locale = ref.read(localeControllerProvider)?.languageCode ?? 'gu';
        unawaited(ref.read(pushRegistrarProvider).register(locale: locale));
      }
    });

    final router = ref.watch(routerProvider);
    final chosen = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      // Version gate and maintenance banner above every route.
      builder: (context, child) => AppGate(child: child ?? const SizedBox.shrink()),
      locale: chosen,
      supportedLocales: supportedAppLocales,
      localeListResolutionCallback: (deviceLocales, _) => resolveAppLocale(chosen, deviceLocales),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
