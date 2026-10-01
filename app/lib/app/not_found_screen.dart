import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../l10n/app_localizations.dart';

/// Shown for unknown routes and malformed deep links — never a crash.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: l10n.commonPageNotFound,
        actionLabel: l10n.commonGoHome,
        onAction: () => context.go('/home'),
      ),
    );
  }
}
