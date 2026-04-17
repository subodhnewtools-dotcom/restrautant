import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/messages_dao.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';

/// Repository for managing message templates
class MessagesRepository {
  final MessagesDao _messagesDao;
  final ApiClient _apiClient;

  MessagesRepository(this._messagesDao, this._apiClient);

  /// Get all message templates from local DB
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final templates = await _messagesDao.getAll();
    return templates.map((t) => t.toMap()).toList();
  }

  /// Get single template by ID
  Future<Map<String, dynamic>?> getTemplateById(int id) async {
    final template = await _messagesDao.getById(id);
    return template?.toMap();
  }

  /// Create new message template
  Future<int> createTemplate({
    required String title,
    required String body,
  }) async {
    final template = MessageTemplateCompanion.insert(
      title: title,
      body: body,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      synced: false,
    );

    final id = await _messagesDao.insert(template);
    
    // Add to sync queue
    await _addToSyncQueue(id, 'INSERT', title, body);
    
    // Try to sync immediately if online
    _trySyncTemplate(id);
    
    return id;
  }

  /// Update existing template
  Future<void> updateTemplate({
    required int id,
    required String title,
    required String body,
  }) async {
    final template = MessageTemplateCompanion(
      title: Value(title),
      body: Value(body),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      synced: Value(false),
    );

    await _messagesDao.update(id, template);
    
    // Add to sync queue
    await _addToSyncQueue(id, 'UPDATE', title, body);
    
    // Try to sync immediately if online
    _trySyncTemplate(id);
  }

  /// Delete template
  Future<void> deleteTemplate(int id) async {
    await _messagesDao.delete(id);
    
    // Add to sync queue
    await _addToSyncQueue(id, 'DELETE', '', '');
    
    // Try to sync immediately if online
    _trySyncTemplate(id);
  }

  /// Add operation to sync queue
  Future<void> _addToSyncQueue(
    int recordId,
    String operation,
    String title,
    String body,
  ) async {
    final dao = db.syncQueueDao;
    await dao.addToQueue(SyncQueueCompanion(
      entityType: Value('message_template'),
      entityId: Value(recordId.toString()),
      operation: Value(operation),
      payload: Value({
        'title': title,
        'body': body,
      }),
      synced: Value(false),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Try to sync template to server
  Future<void> _trySyncTemplate(int id) async {
    try {
      final template = await _messagesDao.getById(id);
      if (template == null) return;

      final data = {
        'title': template.title,
        'body': template.body,
      };

      if (template.id == 0) {
        // New record - POST
        await _apiClient.post(Endpoints.messages, data: data);
      } else {
        // Existing record - PUT
        await _apiClient.put('${Endpoints.messages}/${template.id}', data: data);
      }

      // Mark as synced
      await _messagesDao.update(
        template.id,
        MessageTemplateCompanion(synced: Value(true)),
      );
    } catch (e) {
      // Will be synced later by sync service
      print('Sync failed: $e');
    }
  }

  /// Sync all pending messages
  Future<void> syncPending() async {
    final unsynced = await _messagesDao.getUnsynced();
    for (final template in unsynced) {
      await _trySyncTemplate(template.id);
    }
  }
}

/// Provider for MessagesRepository
final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return MessagesRepository(db.messagesDao, apiClient);
});
