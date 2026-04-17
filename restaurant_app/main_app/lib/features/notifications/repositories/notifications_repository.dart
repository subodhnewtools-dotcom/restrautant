import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';

/// Repository for managing notifications
class NotificationsRepository {
  final AppDatabase _db;
  final ApiClient _apiClient;

  NotificationsRepository(this._db, this._apiClient);

  /// Get all notifications from local DB
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    // Fetch from notifications_log table
    try {
      final results = await _db.select(_db.notificationsLog).get();
      return results.map((n) => n.toMap()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int id) async {
    final notif = NotificationsLogCompanion(
      isRead: Value(true),
    );
    
    // Update in database
    // Implementation depends on DAO structure
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    // Update all unread notifications
    // Implementation depends on DAO structure
  }

  /// Delete notification
  Future<void> deleteNotification(int id) async {
    // Delete from database
    // Implementation depends on DAO structure
  }

  /// Send push notification (admin only)
  Future<void> sendNotification({
    required String topic,
    required String title,
    required String body,
  }) async {
    try {
      await _apiClient.post(Endpoints.sendNotification, data: {
        'topic': topic,
        'title': title,
        'body': body,
      });
    } catch (e) {
      print('Failed to send notification: $e');
      rethrow;
    }
  }

  /// Save received notification to local DB
  Future<void> saveNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final notif = NotificationsLogCompanion.insert(
      title: title,
      body: body,
      payload: payload != null ? _mapToString(payload) : '',
      isRead: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    // Insert into database
    // Implementation depends on DAO structure
  }

  String _mapToString(Map<String, dynamic> map) {
    // Convert map to JSON string
    return map.toString();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final results = await (_db.select(_db.notificationsLog)..where((t) => t.isRead.equals(false))).get();
      return results.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications() async {
    final thirtyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    
    // Delete notifications older than 30 days
    // Implementation depends on DAO structure
  }
}

/// Provider for NotificationsRepository
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRepository(db, apiClient);
});
