import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Wraps a screen that holds unsaved work. Ordinary navigation is never
/// interrupted; only when [hasUnsavedChanges] is true does Back ask once,
/// with the consequence stated plainly.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({super.key, required this.hasUnsavedChanges, required this.child});

  final bool hasUnsavedChanges;
  final Widget child;

  static Future<bool> confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedTitle),
        content: Text(l10n.unsavedBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.unsavedDiscard)),
          FilledButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.unsavedKeepEditing)),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmDiscard(context)) navigator.pop(result);
      },
      child: child,
    );
  }
}
