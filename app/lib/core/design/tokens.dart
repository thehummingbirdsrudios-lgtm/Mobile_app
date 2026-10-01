import 'package:flutter/material.dart';

/// Design tokens: the single source for colour, type, spacing, radius and
/// elevation. Screens and components must use these — never raw values.
///
/// Palette rationale: warm ivory surfaces and near-black ink keep the
/// jewellery photography as the richest colour on screen; antique gold is a
/// restrained accent. Text/background pairs meet WCAG 2.2 AA (see
/// docs/architecture/ui-principles.md for measured contrast ratios).
abstract final class AppColors {
  static const ink = Color(0xFF1B1A17);
  static const inkSoft = Color(0xFF3A3731);
  static const muted = Color(0xFF6B655C);
  static const background = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF3EEE6);
  static const divider = Color(0xFFE7E0D5);

  /// Accent for selection, highlights and large marks (not body text).
  static const gold = Color(0xFFA57C2C);

  /// Gold dark enough for text and small icons on light surfaces.
  static const goldText = Color(0xFF7A5A1C);
  static const goldTint = Color(0xFFF4EBD9);

  static const success = Color(0xFF276F45); // 5.3:1 on successTint (AA for small text)
  static const successTint = Color(0xFFE6F2EA);
  static const warning = Color(0xFF9A5B00);
  static const warningTint = Color(0xFFFBF0DF);
  static const error = Color(0xFFB3261E);
  static const errorTint = Color(0xFFFBE9E7);
  static const info = Color(0xFF2F5D8A);
  static const infoTint = Color(0xFFE8EFF6);

  static const onInk = Color(0xFFFAF7F2);
  static const scrim = Color(0x661B1A17);
  static const skeletonBase = Color(0xFFEDE7DD);
  static const skeletonHighlight = Color(0xFFF7F3EC);
}

/// 4-pt spacing scale.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 56.0;

  /// Standard horizontal page gutter on phones.
  static const gutter = md;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const control = BorderRadius.all(Radius.circular(md));
  static const sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class AppElevation {
  static const none = <BoxShadow>[];
  static const low = [BoxShadow(color: Color(0x0F1B1A17), blurRadius: 6, offset: Offset(0, 1))];
  static const medium = [BoxShadow(color: Color(0x141B1A17), blurRadius: 16, offset: Offset(0, 4))];
  static const high = [BoxShadow(color: Color(0x1F1B1A17), blurRadius: 32, offset: Offset(0, 12))];
}

/// Minimum interactive target (WCAG 2.2 target size, Material 48dp).
const double kMinTouchTarget = 48;

/// Type scale. Body text is never below 16 for readability; captions 12 are
/// reserved for secondary metadata only.
abstract final class AppType {
  static const family = 'HindVadodara';

  /// Devanagari (Hindi) glyphs come from Hind, same design family.
  static const fallback = <String>['Hind'];

  static const display = TextStyle(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w600, letterSpacing: -0.4);
  static const heading = TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static const title = TextStyle(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400);
  static const bodyStrong = TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600);
  static const bodySmall = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const caption = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, letterSpacing: 0.2);

  /// Money and design numbers: tabular figures so columns align.
  static const figures = <FontFeature>[FontFeature.tabularFigures()];
}
