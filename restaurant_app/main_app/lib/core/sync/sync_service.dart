import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../database/app_database.dart';
import '../database/daos/all_daos.dart';
import '../network/api_client.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

class SyncResult {
  final bool success;
  final String? errorMessage;
  final int itemsSynced;
  final DateTime? lastSyncTime;

  SyncResult({
    required this.success,
    this.errorMessage,
    this.itemsSynced = 0,
    this.lastSyncTime,
  });
}

class SyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService(this._db, this._apiClient);

  Stream<SyncStatus> get syncStatusStream => _statusController.stream;

  void startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: kSyncIntervalSecs),
      (_) => syncNow(),
    );
  }

  void stopBackgroundSync() {
    _syncTimer?.cancel();
  }

  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return SyncResult(success: false, errorMessage: 'Sync already in progress');
    }

    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _statusController.add(SyncStatus.offline);
        _isSyncing = false;
        return SyncResult(
          success: false,
          errorMessage: 'No internet connection',
        );
      }

      int totalItemsSynced = 0;

      // Fetch full sync data from server
      final response = await _apiClient.get('/sync/full_sync');
      final syncData = response.data as Map<String, dynamic>;

      // Sync categories
      if (syncData.containsKey('categories')) {
        final categoriesDao = _db.categoriesDao;
        final categories = (syncData['categories'] as List)
            .map((c) => MenuCategoriesCompanion.insert(
                  id: c['id'],
                  name: c['name'],
                  type: c['type'],
                  sortOrder: c['sort_order'],
                  synced: 1,
                ))
            .toList();
        
        await categoriesDao.upsertAll(categories);
        totalItemsSynced += categories.length;
      }

      // Sync menu items
      if (syncData.containsKey('menu_items')) {
        final itemsDao = _db.itemsDao;
        final items = (syncData['menu_items'] as List)
            .map((item) => MenuItemsCompanion.insert(
                  id: item['id'],
                  categoryId: item['category_id'],
                  name: item['name'],
                  price: item['price'].toDouble(),
                  imageUrl: item['image_url'],
                  description: item['description'] ?? '',
                  isVeg: item['is_veg'] == 1,
                  isLowStock: item['is_low_stock'] == 1,
                  isActive: item['is_active'] == 1,
                  synced: 1,
                ))
            .toList();
        
        await itemsDao.upsertAll(items);
        totalItemsSynced += items.length;

        // Download images that don't exist locally
        await _downloadMissingImages(syncData['menu_items'] as List);
      }

      // Sync bill templates
      if (syncData.containsKey('bill_templates')) {
        final templatesDao = _db.templatesDao;
        final templates = (syncData['bill_templates'] as List)
            .map((t) => BillTemplatesCompanion.insert(
                  id: t['id'],
                  brandName: t['brand_name'],
                  footerText: t['footer_text'],
                  logoUrl: t['logo_url'] ?? '',
                  fontStyle: t['font_style'] ?? 'default',
                  accentColor: t['accent_color'] ?? '#E8630A',
                  synced: 1,
                ))
            .toList();
        
        await templatesDao.upsertAll(templates);
        totalItemsSynced += templates.length;
      }

      // Sync message templates
      if (syncData.containsKey('messages')) {
        final messagesDao = _db.messagesDao;
        final messages = (syncData['messages'] as List)
            .map((m) => MessageTemplatesCompanion.insert(
                  id: m['id'],
                  title: m['title'],
                  body: m['body'],
                  synced: 1,
                ))
            .toList();
        
        await messagesDao.upsertAll(messages);
        totalItemsSynced += messages.length;
      }

      // Sync CMS content
      if (syncData.containsKey('cms')) {
        final cmsDao = _db.cmsDao;
        final cmsSections = syncData['cms'] as Map<String, dynamic>;
        
        for (var entry in cmsSections.entries) {
          await cmsDao.upsert(CmsContentCompanion.insert(
            sectionKey: entry.key,
            contentJson: jsonEncode(entry.value),
            synced: 1,
          ));
        }
        totalItemsSynced += cmsSections.length;
      }

      // Process sync queue (upload pending changes)
      final processedCount = await _processSyncQueue();
      totalItemsSynced += processedCount;

      // Update last sync time
      final now = DateTime.now();
      await _db.syncMetadataDao.updateLastSyncTime(now);

      _statusController.add(SyncStatus.success);
      _isSyncing = false;

      return SyncResult(
        success: true,
        itemsSynced: totalItemsSynced,
        lastSyncTime: now,
      );
    } catch (e) {
      _statusController.add(SyncStatus.error);
      _isSyncing = false;
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _downloadMissingImages(List<dynamic> items) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/images');
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    for (var item in items) {
      final imageUrl = item['image_url'] as String;
      if (imageUrl.isEmpty) continue;

      final fileName = imageUrl.split('/').last;
      final localPath = '${imagesDir.path}/$fileName';
      final file = File(localPath);

      if (!await file.exists()) {
        try {
          final response = await _apiClient.dio.get(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          await file.writeAsBytes(response.data);
        } catch (e) {
          // Skip failed downloads
          print('Failed to download image: $imageUrl');
        }
      }
    }
  }

  Future<int> _processSyncQueue() async {
    final queueDao = _db.syncQueueDao;
    final pendingItems = await queueDao.getAllPending();
    
    int processedCount = 0;

    for (var item in pendingItems) {
      try {
        switch (item.operation) {
          case 'CREATE':
            await _handleCreateOperation(item);
            break;
          case 'UPDATE':
            await _handleUpdateOperation(item);
            break;
          case 'DELETE':
            await _handleDeleteOperation(item);
            break;
        }
        
        await queueDao.deleteById(item.id);
        processedCount++;
      } catch (e) {
        print('Failed to process sync queue item ${item.id}: $e');
        // Keep item in queue for retry
      }
    }

    return processedCount;
  }

  Future<void> _handleCreateOperation(SyncQueueItem item) async {
    final data = jsonDecode(item.data);
    
    switch (item.entityType) {
      case 'menu_item':
        await _apiClient.postMultipart(
          '/menu/items',
          data,
          item.localImagePath != null ? {'image': item.localImagePath!} : null,
        );
        break;
      case 'bill':
        await _apiClient.post('/billing/bills', data);
        break;
      case 'category':
        await _apiClient.post('/menu/categories', data);
        break;
      case 'message':
        await _apiClient.post('/messages', data);
        break;
      case 'cms':
        await _apiClient.put('/cms/${data['section_key']}', data);
        break;
    }
  }

  Future<void> _handleUpdateOperation(SyncQueueItem item) async {
    final data = jsonDecode(item.data);
    
    switch (item.entityType) {
      case 'menu_item':
        await _apiClient.putMultipart(
          '/menu/items/${item.serverId}',
          data,
          item.localImagePath != null ? {'image': item.localImagePath!} : null,
        );
        break;
      case 'bill':
        await _apiClient.put('/billing/bills/${item.serverId}', data);
        break;
      case 'category':
        await _apiClient.put('/menu/categories/${item.serverId}', data);
        break;
      case 'message':
        await _apiClient.put('/messages/${item.serverId}', data);
        break;
      case 'cms':
        await _apiClient.put('/cms/${data['section_key']}', data);
        break;
    }
  }

  Future<void> _handleDeleteOperation(SyncQueueItem item) async {
    switch (item.entityType) {
      case 'menu_item':
        await _apiClient.delete('/menu/items/${item.serverId}');
        break;
      case 'category':
        await _apiClient.delete('/menu/categories/${item.serverId}');
        break;
      case 'bill':
        await _apiClient.delete('/billing/bills/${item.serverId}');
        break;
      case 'message':
        await _apiClient.delete('/messages/${item.serverId}');
        break;
    }
  }

  Future<void> addToSyncQueue({
    required String entityType,
    required String operation,
    required Map<String, dynamic> data,
    int? serverId,
    String? localImagePath,
  }) async {
    await _db.syncQueueDao.insert(SyncQueueItemsCompanion.insert(
      entityType: entityType,
      operation: operation,
      data: jsonEncode(data),
      serverId: serverId,
      localImagePath: localImagePath,
      createdAt: DateTime.now(),
      synced: 0,
    ));
  }

  void dispose() {
    _syncTimer?.cancel();
    _statusController.close();
  }
}
