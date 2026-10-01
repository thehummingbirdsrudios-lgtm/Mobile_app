import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'tokens.dart';

/// Builds the Material theme from design tokens so stock widgets (fields,
/// dialogs, nav bars) match custom components without per-screen styling.
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.onInk,
    secondary: AppColors.gold,
    onSecondary: AppColors.ink,
    tertiary: AppColors.goldText,
    onTertiary: AppColors.onInk,
    error: AppColors.error,
    onError: AppColors.surface,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.muted,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.surfaceMuted,
    surfaceContainerHigh: AppColors.surfaceMuted,
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,
    secondaryContainer: AppColors.goldTint,
    onSecondaryContainer: AppColors.goldText,
  );

  TextStyle t(TextStyle s, [Color color = AppColors.ink]) =>
      s.copyWith(color: color, fontFamily: AppType.family, fontFamilyFallback: AppType.fallback);

  final textTheme = TextTheme(
    displaySmall: t(AppType.display),
    headlineSmall: t(AppType.heading),
    titleLarge: t(AppType.title),
    titleMedium: t(AppType.bodyStrong),
    bodyLarge: t(AppType.body),
    bodyMedium: t(AppType.bodySmall, AppColors.inkSoft),
    labelLarge: t(AppType.label),
    labelMedium: t(AppType.caption, AppColors.muted),
    bodySmall: t(AppType.caption, AppColors.muted),
  );

  const fieldBorder = OutlineInputBorder(
    borderRadius: AppRadius.control,
    borderSide: BorderSide(color: AppColors.divider),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppType.family,
    fontFamilyFallback: AppType.fallback,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: t(AppType.title),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.ink, width: 1.5)),
      errorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      labelStyle: t(AppType.body, AppColors.muted),
      floatingLabelStyle: t(AppType.label, AppColors.ink),
      errorStyle: t(AppType.caption, AppColors.error).copyWith(fontSize: 13),
      errorMaxLines: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.goldTint,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? AppColors.goldText : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => t(
          AppType.caption,
          states.contains(WidgetState.selected) ? AppColors.ink : AppColors.muted,
        ).copyWith(fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.goldTint,
      selectedIconTheme: const IconThemeData(color: AppColors.goldText),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle: t(AppType.label),
      unselectedLabelTextStyle: t(AppType.label, AppColors.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      showDragHandle: true,
      dragHandleColor: AppColors.divider,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      titleTextStyle: t(AppType.title),
      contentTextStyle: t(AppType.body, AppColors.inkSoft),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: t(AppType.bodyStrong, AppColors.onInk),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      insetPadding: const EdgeInsets.all(AppSpacing.md),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: AppSpacing.sm,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      titleTextStyle: t(AppType.bodyStrong),
      subtitleTextStyle: t(AppType.bodySmall, AppColors.muted),
      iconColor: AppColors.inkSoft,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink, strokeWidth: 2.5),
  );
}
