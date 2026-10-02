import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_tokens.dart';

/// [PushTokenSource] backed by Firebase Cloud Messaging (Android).
///
/// Deliberately thin: every rule (when to register, what a tap opens, what a
/// foreground message refreshes) lives behind the port and is tested with a
/// fake. Background and terminated pushes are shown by Android itself from
/// the notification payload, so there is no Dart background handler.
class FirebasePushTokens implements PushTokenSource {
  FirebasePushTokens(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  String get platform => 'android';

  @override
  Future<String?> currentToken() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
      return await _messaging.getToken();
    } on Object {
      // No Play services, offline, or blocked: the inbox still works.
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<void> reset() async {
    try {
      await _messaging.deleteToken();
    } on Object {
      // Offline: the server still drops the token at the next registration.
    }
  }

  @override
  Stream<PushMessage> get foregroundMessages => _vepari(FirebaseMessaging.onMessage);

  @override
  Stream<PushMessage> get openedMessages => _vepari(FirebaseMessaging.onMessageOpenedApp);

  @override
  Future<PushMessage?> initialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      return message == null ? null : _parse(message);
    } on Object {
      return null;
    }
  }

  static Stream<PushMessage> _vepari(Stream<RemoteMessage> messages) =>
      messages.map(_parse).where((m) => m != null).cast<PushMessage>();

  static PushMessage? _parse(RemoteMessage m) => PushMessage.fromData(m.data, title: m.notification?.title);
}
