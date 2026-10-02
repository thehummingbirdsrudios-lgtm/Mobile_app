import 'package:meta/meta.dart';

import '../../../core/state/paged.dart';

/// One inbox entry. [args] hold only what the recipient may already see
/// (the server chose them); the target is re-authorised when opened.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.targetKind,
    this.targetId,
    this.args = const {},
    this.readAt,
  });

  final String id;

  /// 'new_maal' | 'order_update' | 'payment_received' (unknown kinds are shown generically).
  final String kind;
  final String? targetKind;
  final String? targetId;
  final Map<String, Object?> args;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}

typedef NotificationCursor = ({DateTime createdAt, String id});

/// Notifications port. Implementations throw `AppFailure`.
abstract interface class NotificationsRepository {
  Future<PageResult<AppNotification, NotificationCursor>> page({NotificationCursor? before, int limit});

  /// Unread count, capped by the server at 100.
  Future<int> unreadCount();

  /// Marks [ids] read, or everything when null.
  Future<void> markRead({List<String>? ids});

  Future<void> registerDevice({required String token, required String platform, required String locale});
  Future<void> unregisterDevice(String token);
}
