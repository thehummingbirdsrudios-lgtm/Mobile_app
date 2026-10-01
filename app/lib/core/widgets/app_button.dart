import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../motion/motion.dart';
import 'success_check.dart';

enum AppButtonVariant { primary, secondary, quiet }

enum _Phase { idle, busy, success }

/// The app's one button. Answers "did my tap register?" every time:
/// pressed (scale) → busy (spinner, after a short delay so fast actions don't
/// flash) → success (check) → idle. While busy it ignores further taps, so a
/// double/triple tap can never submit an order or payment twice (the server
/// is idempotent too — this is the first line, not the only one).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
    this.confirmSuccess = false,
    this.onError,
  });

  final String label;
  final IconData? icon;

  /// Null disables the button. May be async; the button stays busy until it completes.
  final FutureOr<void> Function()? onPressed;
  final AppButtonVariant variant;
  final bool expand;

  /// Show the success check after the action completes without error.
  final bool confirmSuccess;

  /// Receives errors thrown by [onPressed]. If absent they are reported to Flutter.
  final void Function(Object error)? onError;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  _Phase _phase = _Phase.idle;
  bool _showSpinner = false;
  bool _pressed = false;
  Timer? _spinnerTimer;
  Timer? _successTimer;

  bool get _enabled => widget.onPressed != null && _phase == _Phase.idle;

  Future<void> _handleTap() async {
    if (!_enabled) return;
    setState(() => _phase = _Phase.busy);
    _spinnerTimer = Timer(AppMotion.loadingDelay, () {
      if (mounted && _phase == _Phase.busy) setState(() => _showSpinner = true);
    });
    var succeeded = false;
    try {
      await widget.onPressed!();
      succeeded = true;
    } catch (error, stack) {
      if (widget.onError != null) {
        widget.onError!(error);
      } else {
        FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'AppButton'));
      }
    } finally {
      _spinnerTimer?.cancel();
      if (mounted) {
        if (succeeded && widget.confirmSuccess) {
          unawaited(HapticFeedback.lightImpact());
          setState(() {
            _phase = _Phase.success;
            _showSpinner = false;
          });
          _successTimer = Timer(const Duration(milliseconds: 1100), () {
            if (mounted) setState(() => _phase = _Phase.idle);
          });
        } else {
          setState(() {
            _phase = _Phase.idle;
            _showSpinner = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }

  ({Color bg, Color fg, BorderSide? border}) _colors() {
    final disabled = widget.onPressed == null;
    return switch (widget.variant) {
      AppButtonVariant.primary => (
        bg: disabled
            ? AppColors.divider
            : _phase == _Phase.success
            ? AppColors.success
            : AppColors.ink,
        fg: disabled ? AppColors.muted : AppColors.onInk,
        border: null,
      ),
      AppButtonVariant.secondary => (
        bg: AppColors.surface,
        fg: disabled ? AppColors.muted : AppColors.ink,
        border: BorderSide(color: disabled ? AppColors.divider : AppColors.ink.withValues(alpha: 0.2)),
      ),
      AppButtonVariant.quiet => (
        bg: Colors.transparent,
        fg: disabled ? AppColors.muted : AppColors.goldText,
        border: null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(color: c.fg, fontSize: 16);

    final Widget content = switch (_phase) {
      _Phase.success => SuccessCheck(key: const ValueKey('success'), color: c.fg, size: 22),
      _Phase.busy when _showSpinner => SizedBox.square(
        key: const ValueKey('busy'),
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: c.fg),
      ),
      _ => Row(
        key: const ValueKey('idle'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[Icon(widget.icon, size: 20, color: c.fg), const SizedBox(width: AppSpacing.xs)],
          Flexible(
            child: Text(widget.label, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    };

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      liveRegion: _phase != _Phase.idle,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppMotion.of(context, AppMotion.instant),
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          height: 52,
          child: Material(
            color: c.bg,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.control, side: c.border ?? BorderSide.none),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _enabled ? _handleTap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v && _enabled),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(
                  child: AnimatedSwitcher(duration: AppMotion.of(context, AppMotion.quick), child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
