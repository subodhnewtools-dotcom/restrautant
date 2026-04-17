import 'package:drift/drift.dart';
import '../app_database.dart';

part 'notifications_log_dao.g.dart';

@DriftAccessor(tables: [NotificationsLog])
class NotificationsLogDao extends DatabaseAccessor<AppDatabase> with _$NotificationsLogDaoMixin {
  Future<List<NotificationLogItem>> getAllNotifications({int limit = 100, bool? unreadOnly}) async {
    var query = select(notificationsLog)..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])..limit(limit);
    
    if (unreadOnly == true) {
      query = query..where((t) => t.isRead.equals(false));
    }
    
    return query.get();
  }

  Future<NotificationLogItem?> getNotificationById(int id) async {
    return (select(notificationsLog)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertNotification(NotificationsLogCompanion notification) async {
    return into(notificationsLog).insert(notification);
  }

  Future<bool> markAsRead(int id) async {
    return (update(notificationsLog)..where((t) => t.id.equals(id))).write(
      NotificationsLogCompanion(isRead: Value(true)),
    );
  }

  Future<bool> markAllAsRead() async {
    return (update(notificationsLog)..where((t) => t.isRead.equals(false))).write(
      NotificationsLogCompanion(isRead: Value(true)),
    );
  }

  Future<int> getUnreadCount() async {
    final unread = await (select(notificationsLog)..where((t) => t.isRead.equals(false))).get();
    return unread.length;
  }

  Stream<List<NotificationLogItem>> watchAllNotifications({int limit = 100}) {
    return (select(notificationsLog)..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])..limit(limit)).watch();
  }
}
