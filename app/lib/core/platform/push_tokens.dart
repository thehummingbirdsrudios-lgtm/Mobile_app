import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where this install's push token comes from (FCM on Android). The app
/// works fully without one: notifications stay in the in-app inbox.
abstract interface class PushTokenSource {
  /// 'android' | 'ios' | 'web'
  String get platform;

  /// The current token, or null when push is unavailable or not allowed.
  Future<String?> currentToken();

  /// New tokens after the platform rotates them.
  Stream<String> get tokenRefreshes;
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
}

final pushTokenSourceProvider = Provider<PushTokenSource>((ref) => const NoPushTokens());
