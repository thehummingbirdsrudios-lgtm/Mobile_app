import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/core.dart';
import '../l10n/app_localizations.dart';

/// Breakpoints (logical pixels).
abstract final class Breakpoints {
  static const rail = 600.0;
  static const extendedRail = 1100.0;
}

/// Six primary destinations; one design language from phone to desktop:
/// bottom bar on phones, navigation rail on tablets/desktop.
///
/// Back behaviour: on the root of any tab other than Home, system Back goes
/// to Home first; Back on Home leaves the app (platform convention).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.diamond_outlined, Icons.diamond_rounded, l10n.navMaal),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, l10n.navOrder),
      (Icons.people_alt_outlined, Icons.people_alt_rounded, l10n.navCustomer),
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, l10n.navHisaab),
      (Icons.menu_rounded, Icons.menu_rounded, l10n.navMore),
    ];
    final width = MediaQuery.sizeOf(context).width;
    final index = navigationShell.currentIndex;

    final body = PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: navigationShell,
    );

    if (width >= Breakpoints.rail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: width >= Breakpoints.extendedRail,
              selectedIndex: index,
              onDestinationSelected: _select,
              labelType: width >= Breakpoints.extendedRail ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: BrandMark(size: 40),
              ),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _select,
          destinations: [
            for (final (icon, selected, label) in destinations)
              NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label, tooltip: ''),
          ],
        ),
      ),
    );
  }
}
