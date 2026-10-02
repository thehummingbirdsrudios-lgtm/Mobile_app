import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/notification_providers.dart';

/// Announces a push that arrives while the app is open (Android shows those
/// only in the bell): a short note with an Open action. Sits above every
/// route, so it works on any screen.
class PushMessageListener extends ConsumerStatefulWidget {
  const PushMessageListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushMessageListener> createState() => _PushMessageListenerState();
}

class _PushMessageListenerState extends ConsumerState<PushMessageListener> {
  StreamSubscription<PushMessage>? _arrivals;

  @override
  void initState() {
    super.initState();
    _arrivals = ref.read(pushMessagesProvider).arrivals.listen(_show);
  }

  void _show(PushMessage m) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final title = m.title?.trim();
    AppFeedback.show(
      context,
      title == null || title.isEmpty ? l10n.pushNewNotification : title,
      tone: FeedbackTone.info,
      actionLabel: l10n.pushOpen,
      onAction: () => unawaited(ref.read(pushMessagesProvider).open(m)),
    );
  }

  @override
  void dispose() {
    unawaited(_arrivals?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
