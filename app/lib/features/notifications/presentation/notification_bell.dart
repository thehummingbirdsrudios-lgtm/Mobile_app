import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/notification_providers.dart';

/// Bell with the unread count; opens the inbox. The count is re-read when
/// the app returns to the foreground.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  late final _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(unreadCountProvider));

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
    final l10n = AppLocalizations.of(context);
    // A failed count simply shows no badge; the inbox has its own error state.
    final count = ref.watch(unreadCountProvider).value ?? 0;
    return IconButton(
      tooltip: count == 0 ? l10n.notificationsTitle : l10n.notificationsUnread(count),
      onPressed: ref.read(appNavigatorProvider).openNotifications,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.goldText, // white label meets AA on it
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
