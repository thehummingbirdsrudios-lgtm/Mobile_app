import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/app_status_provider.dart';

/// Wraps the whole app: blocks builds older than the server's minimum
/// version, and shows a banner while business writes are paused for
/// maintenance. Re-checks when the app returns to the foreground.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  late final _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(appStatusProvider));

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appStatusProvider).value;
    final version = ref.watch(appConfigProvider).appVersion;
    if (status != null && status.blocks(version)) return _UpdateRequired(version: version);
    if (status?.maintenance ?? false) {
      return Column(
        children: [
          const _MaintenanceBanner(),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child),
          ),
        ],
      );
    }
    return widget.child;
  }
}

class _MaintenanceBanner extends StatelessWidget {
  const _MaintenanceBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.warningTint,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.build_circle_outlined, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.maintenanceBanner,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateRequired extends ConsumerWidget {
  const _UpdateRequired({required this.version});

  final String version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 72),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.updateRequiredTitle, style: text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.updateRequiredBody(version), style: text.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.updateCheckAgain,
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ref.refresh(appStatusProvider.future),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
