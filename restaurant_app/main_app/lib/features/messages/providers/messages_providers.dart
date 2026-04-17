import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_template_model.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';

class MessagesRepository {
  final AppDatabase _db;
  final ApiClient _api;

  MessagesRepository(this._db, this._api);

  Future<List<MessageTemplateModel>> getMessages() async {
    // Try local DB first
    final localMessages = await _db.messageTemplateDao.getAll();
    
    // Sync with server if online
    try {
      final response = await _api.get('/messages');
      final List<dynamic> data = response.data['data'] ?? [];
      
      for (var item in data) {
        await _db.messageTemplateDao.upsert(MessageTemplateModel.fromMap(item));
      }
      
      return await _db.messageTemplateDao.getAll();
    } catch (_) {
      // Return local data if offline
      return localMessages.map((e) => MessageTemplateModel.fromMap(e.toMap())).toList();
    }
  }

  MessageTemplateModel? getMessageById(String id) {
    return _db.messageTemplateDao.getById(id);
  }

  Future<void> saveMessage(MessageTemplateModel message) async {
    // Save to local DB first
    await _db.messageTemplateDao.upsert(message);
    
    // Queue for sync
    await _db.syncQueueDao.insert({
      'table_name': 'message_templates',
      'record_id': message.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'action': message.id == null ? 'INSERT' : 'UPDATE',
      'data': JSON.stringify(message.toMap()),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Try to sync immediately if online
    try {
      if (message.id == null) {
        await _api.post('/messages', data: message.toMap());
      } else {
        await _api.put('/messages/${message.id}', data: message.toMap());
      }
    } catch (_) {
      // Will sync later
    }
  }

  Future<void> deleteMessage(String id) async {
    // Delete from local DB
    await _db.messageTemplateDao.delete(id);
    
    // Queue for sync
    await _db.syncQueueDao.insert({
      'table_name': 'message_templates',
      'record_id': id,
      'action': 'DELETE',
      'data': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Try to delete from server if online
    try {
      await _api.delete('/messages/$id');
    } catch (_) {
      // Will sync later
    }
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final messagesProvider = FutureProvider<List<MessageTemplateModel>>((ref) async {
  return ref.read(messagesRepositoryProvider).getMessages();
});
