import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/state/paged.dart';
import '../../domain/notifications.dart';

/// Remote data source: inbox RPCs (SECURITY INVOKER, own rows only) and the
/// device-token RPCs.
class NotificationsApi {
  const NotificationsApi(this._api);

  final ApiClient _api;

  Future<PageResult<AppNotification, NotificationCursor>> page({NotificationCursor? before, required int limit}) async {
    final rows = await _api.rpc(
      'notification_page',
      params: {'p_before_at': before?.createdAt.toUtc().toIso8601String(), 'p_before_id': before?.id, 'p_limit': limit},
      decode: (json) => [for (final r in (json as List? ?? const [])) notificationFromJson(asJsonObject(r))],
    );
    return PageResult(rows, next: rows.length < limit ? null : (createdAt: rows.last.createdAt, id: rows.last.id));
  }

  Future<int> unreadCount() =>
      _api.rpc('unread_notification_count', decode: (json) => json is int ? json : throw FormatException('$json'));

  Future<void> markRead({List<String>? ids}) =>
      _api.rpc('mark_notifications_read', params: {'p_ids': ids}, decode: (_) {});

  Future<void> registerDevice({required String token, required String platform, required String locale}) => _api.rpc(
    'register_device_token',
    params: {'p_token': token, 'p_platform': platform, 'p_locale': locale},
    decode: (_) {},
  );

  Future<void> unregisterDevice(String token) =>
      _api.rpc('unregister_device_token', params: {'p_token': token}, decode: (_) {});
}

AppNotification notificationFromJson(Map<String, dynamic> j) => AppNotification(
  id: j.requireString('id'),
  kind: j.requireString('kind'),
  targetKind: j.optionalString('target_kind'),
  targetId: j.optionalString('target_id'),
  args: j['args'] is Map ? Map<String, Object?>.from(j['args'] as Map) : const {},
  readAt: j.optionalDateTime('read_at'),
  createdAt: j.requireDateTime('created_at'),
);
