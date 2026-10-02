import '../../../../core/state/paged.dart';
import '../../domain/notifications.dart';
import '../remote/notifications_api.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsApi _remote;

  @override
  Future<PageResult<AppNotification, NotificationCursor>> page({NotificationCursor? before, int limit = 30}) =>
      _remote.page(before: before, limit: limit);

  @override
  Future<int> unreadCount() => _remote.unreadCount();

  @override
  Future<void> markRead({List<String>? ids}) => _remote.markRead(ids: ids);

  @override
  Future<void> registerDevice({required String token, required String platform, required String locale}) =>
      _remote.registerDevice(token: token, platform: platform, locale: locale);

  @override
  Future<void> unregisterDevice(String token) => _remote.unregisterDevice(token);
}
