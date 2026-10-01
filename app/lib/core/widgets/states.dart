import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/tokens.dart';
import '../errors/app_failure.dart';
import '../motion/motion.dart';
import 'app_button.dart';

/// Deliberate empty state: icon, one sentence, at most ONE action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.goldTint, shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: AppColors.goldText),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: text.titleLarge, textAlign: TextAlign.center),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body!,
                  style: text.bodyLarge!.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: actionLabel!, onPressed: onAction, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state built from an [AppFailure]: plain-language message and a
/// retry button only when retrying can help.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = switch (failure.kind) {
      FailureKind.network => Icons.wifi_off_rounded,
      FailureKind.permissionDenied => Icons.lock_outline_rounded,
      FailureKind.maintenance => Icons.build_circle_outlined,
      _ => Icons.error_outline_rounded,
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.muted),
              const SizedBox(height: AppSpacing.md),
              Text(failure.message(l10n), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              if (onRetry != null && failure.isRetryable) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.retry,
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One shimmer for a whole skeleton region (one animation controller, not
/// one per box). Static when reduced motion is requested.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final t = _controller.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(-0.5 + 3 * t, 0),
                colors: const [AppColors.skeletonBase, AppColors.skeletonHighlight, AppColors.skeletonBase],
              ).createShader(bounds),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

/// A placeholder block inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: AppColors.skeletonBase, borderRadius: BorderRadius.circular(radius)),
  );
}

enum FeedbackTone { success, warning, error, info }

/// Short, truthful confirmations. Only call `success` after the server has
/// committed the operation.
abstract final class AppFeedback {
  static void show(BuildContext context, String message, {FeedbackTone tone = FeedbackTone.success}) {
    final (icon, color) = switch (tone) {
      FeedbackTone.success => (Icons.check_circle_rounded, const Color(0xFF7CD39C)),
      FeedbackTone.warning => (Icons.warning_amber_rounded, const Color(0xFFF2C46B)),
      FeedbackTone.error => (Icons.error_rounded, const Color(0xFFF2A39E)),
      FeedbackTone.info => (Icons.info_rounded, const Color(0xFFA9C7E6)),
    };
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2600),
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}
