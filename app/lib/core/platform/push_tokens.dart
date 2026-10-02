import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a push carries (see supabase/functions/push-dispatch): ids only.
/// The notification text on the lock screen comes from the server; the app
/// re-reads and re-authorises the subject before showing anything else.
class PushMessage {
  const PushMessage({required this.notificationId, required this.kind, this.targetKind, this.targetId, this.title});

  final String notificationId;
  final String kind;
  final String? targetKind;
  final String? targetId;

  /// The localised title the server chose (foreground display only).
  final String? title;

  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

  /// Null for anything that is not a well-formed Vepari push.
  static PushMessage? fromData(Map<String, dynamic> data, {String? title}) {
    final id = data['notification_id'];
    final kind = data['kind'];
    if (id is! String || !_uuid.hasMatch(id) || kind is! String || kind.isEmpty) return null;
    final targetKind = data['target_kind'];
    final targetId = data['target_id'];
    final hasTarget = targetKind is String && targetKind.isNotEmpty && targetId is String && _uuid.hasMatch(targetId);
    return PushMessage(
      notificationId: id,
      kind: kind,
      targetKind: hasTarget ? targetKind : null,
      targetId: hasTarget ? targetId : null,
      title: title,
    );
  }
}

/// This install's push channel (FCM on Android). The app works fully
/// without one: notifications stay in the in-app inbox.
abstract interface class PushTokenSource {
  /// 'android' | 'ios' | 'web'
  String get platform;

  /// The current token, or null when push is unavailable or not allowed.
  /// Asks for notification permission first (Android 13+), so call it only
  /// once someone has signed in.
  Future<String?> currentToken();

  /// New tokens after the platform rotates them.
  Stream<String> get tokenRefreshes;

  /// Forgets this install's token (sign-out), so the next login gets a new
  /// one and nothing addressed to the previous member can reach the phone.
  Future<void> reset();

  /// Pushes that arrive while the app is open (Android does not show them).
  Stream<PushMessage> get foregroundMessages;

  /// Pushes the user tapped while the app was in the background.
  Stream<PushMessage> get openedMessages;

  /// The push whose tap started the app, if any (delivered once).
  Future<PushMessage?> initialMessage();
}

/// Default: no push provider configured in this build.
class NoPushTokens implements PushTokenSource {
  const NoPushTokens();

  @override
  String get platform => 'android';

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<void> reset() async {}

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;
}

final pushTokenSourceProvider = Provider<PushTokenSource>((ref) => const NoPushTokens());
