import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/notifications.dart';
import 'notification_targets.dart';

/// Overridden at the composition root and in tests.
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => throw UnimplementedError('notificationsRepositoryProvider must be overridden'),
);

/// Unread count for the bell. Re-read after the user's own actions
/// (business revision), when the inbox changes, and when the app resumes.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  ref
    ..watch(currentSessionProvider.select((s) => s?.tenantId))
    ..watch(businessRevisionProvider);
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

typedef InboxState = PagedState<AppNotification, NotificationCursor>;

final inboxProvider = NotifierProvider.autoDispose<Inbox, InboxState>(Inbox.new);

class Inbox extends Notifier<InboxState> {
  Paginator<AppNotification, NotificationCursor>? _paginator;

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  InboxState build() {
    ref.watch(currentSessionProvider.select((s) => s?.tenantId));
    final paginator = Paginator<AppNotification, NotificationCursor>((cursor) => _repo.page(before: cursor), (s) {
      if (ref.mounted) state = s;
    });
    _paginator = paginator;
    unawaited(Future.microtask(paginator.refresh));
    return const InboxState();
  }

  Future<void> refresh() async {
    await (_paginator?.refresh() ?? Future<void>.value());
    if (ref.mounted) ref.invalidate(unreadCountProvider);
  }

  Future<void> loadMore() => _paginator?.loadMore() ?? Future.value();
  Future<void> retry() => _paginator?.retry() ?? Future.value();

  /// Marks one entry read on the server, then shows it read. Failures are
  /// silent: it stays unread and is marked next time.
  Future<void> markRead(AppNotification n) async {
    if (!n.isUnread) return;
    try {
      await _repo.markRead(ids: [n.id]);
    } on AppFailure {
      return;
    }
    if (!ref.mounted) return;
    _replaceAll((e) => e.id == n.id ? _read(e) : e);
    ref.invalidate(unreadCountProvider);
  }

  /// Throws [AppFailure] so the screen can say why.
  Future<void> markAllRead() async {
    await _repo.markRead();
    if (!ref.mounted) return;
    _replaceAll(_read);
    ref.invalidate(unreadCountProvider);
  }

  static AppNotification _read(AppNotification e) => e.isUnread
      ? AppNotification(
          id: e.id,
          kind: e.kind,
          targetKind: e.targetKind,
          targetId: e.targetId,
          args: e.args,
          readAt: DateTime.now().toUtc(),
          createdAt: e.createdAt,
        )
      : e;

  void _replaceAll(AppNotification Function(AppNotification) update) =>
      state = state.copyWith(items: [for (final e in state.items) update(e)]);
}

/// Registers this install's push token for the signed-in member, and
/// removes it before sign-out so the device stops receiving that member's
/// notifications. Push is optional: every failure leaves the inbox working.
final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(ref);
  ref.onDispose(registrar._dispose);
  return registrar;
});

class PushRegistrar {
  PushRegistrar(this._ref);

  final Ref _ref;
  String? _token;
  StreamSubscription<String>? _refreshes;

  NotificationsRepository get _repo => _ref.read(notificationsRepositoryProvider);
  PushTokenSource get _source => _ref.read(pushTokenSourceProvider);

  /// The token registered for the current member, if any.
  String? get registeredToken => _token;

  Future<void> register({required String locale}) async {
    final token = await _source.currentToken();
    if (token == null) return;
    await _send(token, locale);
    _stopListening();
    _refreshes = _source.tokenRefreshes.listen((next) => unawaited(_send(next, locale)));
  }

  Future<void> _send(String token, String locale) async {
    try {
      await _repo.registerDevice(token: token, platform: _source.platform, locale: locale);
      _token = token;
    } on AppFailure catch (f) {
      _ref.read(appLoggerProvider).warning('push.register_failed', {'kind': f.kind.name});
    }
  }

  /// Best effort and bounded: sign-out never waits more than [timeout] per
  /// step. The token is removed on the server, then forgotten on the phone,
  /// so the next login gets a fresh token that no earlier member ever owned.
  Future<void> unregister({Duration timeout = const Duration(seconds: 2)}) async {
    final token = _token;
    _token = null;
    _stopListening();
    if (token == null) return;
    try {
      await _repo.unregisterDevice(token).timeout(timeout);
    } on Object {
      // Offline: the server re-assigns the token at the next login, and
      // stopped members never receive pushes (push_targets).
    }
    try {
      await _source.reset().timeout(timeout);
    } on Object {
      // Deleting locally failed too: the server-side removal still holds.
    }
  }

  // Not awaited: cancelling has nothing to wait for, and its future may
  // complete in another zone (it would never resume under a fake clock).
  void _stopListening() {
    unawaited(_refreshes?.cancel());
    _refreshes = null;
  }

  void _dispose() => _stopListening();
}

/// Pushes for the signed-in member: a push that arrives while the app is open
/// refreshes the bell and inbox (and is announced via [arrivals]); a tapped
/// push marks its notification read and opens what it is about.
final pushMessagesProvider = Provider<PushMessages>((ref) {
  final messages = PushMessages(ref);
  ref.onDispose(messages._dispose);
  return messages;
});

class PushMessages {
  PushMessages(this._ref);

  final Ref _ref;
  final _arrivals = StreamController<PushMessage>.broadcast();
  StreamSubscription<PushMessage>? _foreground;
  StreamSubscription<PushMessage>? _opened;
  bool _initialHandled = false;

  PushTokenSource get _source => _ref.read(pushTokenSourceProvider);

  /// Pushes received while the app is open, after the bell was refreshed.
  Stream<PushMessage> get arrivals => _arrivals.stream;

  /// Starts handling pushes for the member who just signed in. The push that
  /// launched the app (if any) is opened once, after the first frames, when
  /// the sign-in redirect has settled so Back returns to Home.
  Future<void> start() async {
    stop();
    _foreground = _source.foregroundMessages.listen(_arrived);
    _opened = _source.openedMessages.listen((m) => unawaited(open(m)));
    if (_initialHandled) return;
    _initialHandled = true;
    final first = await _source.initialMessage();
    if (first == null) return;
    await WidgetsBinding.instance.endOfFrame;
    await open(first);
  }

  void _arrived(PushMessage m) {
    _ref
      ..invalidate(unreadCountProvider)
      ..invalidate(inboxProvider);
    if (!_arrivals.isClosed) _arrivals.add(m);
  }

  /// Opens the notification's subject (or the inbox when it has none) and
  /// marks it read. Only for a signed-in member; the screen re-authorises.
  Future<void> open(PushMessage m) async {
    if (_ref.read(currentSessionProvider) == null) return;
    final nav = _ref.read(appNavigatorProvider);
    if (!openNotificationTarget(nav, kind: m.kind, targetKind: m.targetKind, targetId: m.targetId)) {
      nav.openNotifications();
    }
    try {
      await _ref.read(notificationsRepositoryProvider).markRead(ids: [m.notificationId]);
    } on AppFailure {
      // Stays unread; the inbox shows it.
    }
    _ref.invalidate(unreadCountProvider);
  }

  /// Stops handling pushes (sign-out). Not awaited, as in [PushRegistrar].
  void stop() {
    unawaited(_foreground?.cancel());
    unawaited(_opened?.cancel());
    _foreground = null;
    _opened = null;
  }

  void _dispose() {
    stop();
    unawaited(_arrivals.close());
  }
}
