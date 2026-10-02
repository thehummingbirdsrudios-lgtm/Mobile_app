import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/notification_providers.dart';
import '../application/notification_targets.dart';
import '../domain/notifications.dart';
import 'notification_text.dart';

/// The member's inbox, newest first. Opening an entry marks it read and goes
/// to its subject, which the target screen re-authorises.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static void _open(AppNavigator nav, AppNotification n) =>
      openNotificationTarget(nav, kind: n.kind, targetKind: n.targetKind, targetId: n.targetId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(inboxProvider);
    final inbox = ref.read(inboxProvider.notifier);
    final nav = ref.read(appNavigatorProvider);
    final hasUnread = state.items.any((n) => n.isUnread);

    Future<void> markAll() async {
      try {
        await inbox.markAllRead();
      } on AppFailure catch (f) {
        if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (hasUnread) TextButton(onPressed: () => unawaited(markAll()), child: Text(l10n.notificationsMarkAll)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: inbox.refresh,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                PagedSliverBody<AppNotification, NotificationCursor>(
                  state: state,
                  padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.huge),
                  onLoadMore: inbox.loadMore,
                  onRetry: inbox.retry,
                  itemBuilder: (context, n) => _NotificationTile(
                    notification: n,
                    onTap: () {
                      unawaited(inbox.markRead(n));
                      _open(nav, n);
                    },
                  ),
                  skeleton: const Center(
                    child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
                  ),
                  empty: EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: l10n.notificationsEmpty,
                    body: l10n.notificationsEmptyBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final n = notification;
    final icon = switch (n.kind) {
      'new_maal' => Icons.diamond_outlined,
      'order_update' => Icons.receipt_long_outlined,
      'payment_received' => Icons.payments_outlined,
      _ => Icons.notifications_none_rounded,
    };
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: n.isUnread ? AppColors.ink : AppColors.muted),
      title: Text(
        notificationText(l10n, n),
        style: n.isUnread ? text.titleSmall : text.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(AppFormat.dateTime(n.createdAt, locale)),
      trailing: n.isUnread
          ? Semantics(
              label: l10n.notificationsUnread(1),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
