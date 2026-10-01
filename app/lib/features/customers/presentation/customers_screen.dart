import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder until the customers increment lands (docs/plan/implementation-plan.md).
/// It honestly says the section is being built — it never shows fake data.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCustomer)),
      body: EmptyState(icon: Icons.people_alt_outlined, title: l10n.comingSoonTitle, body: l10n.comingSoonBody),
    );
  }
}
