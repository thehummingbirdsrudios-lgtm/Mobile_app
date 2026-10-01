import 'package:flutter/material.dart';

/// One motion system for the whole app (docs/architecture/motion-system.md).
///
/// Principle: response → correctness → polish. Motion explains a change; it
/// never delays work. Every animation uses these tokens and collapses to an
/// instant change when the platform asks to reduce motion.
abstract final class AppMotion {
  /// Press feedback, toggles, small state flips.
  static const instant = Duration(milliseconds: 100);

  /// Fades, chip/button state changes, list item insert.
  static const quick = Duration(milliseconds: 180);

  /// Page transitions, bottom sheets.
  static const standard = Duration(milliseconds: 260);

  /// Success confirmation (check draw) — the longest animation in the app.
  static const emphasized = Duration(milliseconds: 360);

  /// Loading indicators only appear after this delay, so fast responses
  /// never flash a spinner.
  static const loadingDelay = Duration(milliseconds: 250);

  static const standardCurve = Curves.easeOutCubic;
  static const enterCurve = Cubic(0.05, 0.7, 0.1, 1.0);
  static const exitCurve = Cubic(0.3, 0.0, 0.8, 0.15);

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [duration], or zero when the user asked to reduce motion.
  static Duration of(BuildContext context, Duration duration) => reduced(context) ? Duration.zero : duration;
}

/// Page transition: a short fade-through with a 2% scale. Calm, fast, and the
/// reverse (back) animation is the exact mirror, so navigation feels continuous.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.standard;

  @override
  Duration get reverseTransitionDuration => AppMotion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final incoming = CurvedAnimation(parent: animation, curve: AppMotion.enterCurve, reverseCurve: AppMotion.exitCurve);
    final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: AppMotion.standardCurve);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.92).animate(outgoing),
      child: FadeTransition(
        opacity: incoming,
        child: ScaleTransition(scale: Tween<double>(begin: 0.98, end: 1).animate(incoming), child: child),
      ),
    );
  }
}
