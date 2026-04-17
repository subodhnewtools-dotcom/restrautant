import 'dart:io';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';

/// Menu repository - handles all menu operations
class MenuRepository {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final SyncService _syncService;

  MenuRepository(this._db, this._apiClient, this._syncService);

  // ============ Categories ============

  /// Get all categories from local DB
  Future<List<MenuCategory>> getAllCategories() async {
    return await _db.categoriesDao.getAll();
  }

  /// Get category by ID
  Future<MenuCategory?> getCategoryById(int id) async {
    return await _db.categoriesDao.getById(id);
  }

  /// Create new category
  Future<bool> createCategory({
    required String name,
    required String type,
    int sortOrder = 0,
  }) async {
    try {
      // Insert to local DB first
      final category = MenuCategoriesCompanion.insert(
        name: name,
        type: type,
        sortOrder: sortOrder,
        synced: 0,
      );

      final categoryId = await _db.categoriesDao.insert(category);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        entityType: 'category',
        operation: 'CREATE',
        data: {
          'name': name,
          'type': type,
          'sort_order': sortOrder,
        },
        serverId: null,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory({
    required int id,
    required String name,
    required String type,
    int? sortOrder,
  }) async {
    try {
      // Update local DB
      await _db.categoriesDao.update(
        MenuCategoriesCompanion(
          id: Value(id),
          name: Value(name),
          type: Value(type),
          sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
          synced: const Value(0),
        ),
      );

      // Get existing category for server ID
      final existing = await _db.categoriesDao.getById(id);
      
      // Add to sync queue
      await _syncService.addToSyncQueue(
        entityType: 'category',
        operation: 'UPDATE',
        data: {
          'name': name,
          'type': type,
          if (sortOrder != null) 'sort_order': sortOrder,
        },
        serverId: existing?.serverId,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(int id) async {
    try {
      // Get category for server ID
      final category = await _db.categoriesDao.getById(id);
      
      // Delete from local DB (cascade will handle items)
      await _db.categoriesDao.deleteById(id);

      // Add to sync queue
      if (category?.serverId != null) {
        await _syncService.addToSyncQueue(
          entityType: 'category',
          operation: 'DELETE',
          data: {},
          serverId: category!.serverId,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ Menu Items ============

  /// Get items by category
  Future<List<MenuItem>> getItemsByCategory(int categoryId) async {
    return await _db.itemsDao.getByCategory(categoryId);
  }

  /// Get all items
  Future<List<MenuItem>> getAllItems() async {
    return await _db.itemsDao.getAll();
  }

  /// Get item by ID
  Future<MenuItem?> getItemById(int id) async {
    return await _db.itemsDao.getById(id);
  }

  /// Create new menu item
  Future<bool> createMenuItem({
    required String name,
    required double price,
    required int categoryId,
    String? description,
    bool isVeg = true,
    bool isLowStock = false,
    File? imageFile,
  }) async {
    try {
      // Insert to local DB
      final item = MenuItemsCompanion.insert(
        categoryId: categoryId,
        name: name,
        price: price,
        description: description ?? '',
        isVeg: isVeg,
        isLowStock: isLowStock,
        isActive: true,
        imageUrl: '',
        synced: 0,
      );

      final itemId = await _db.itemsDao.insert(item);

      // Handle image upload and sync
      String? imagePath;
      if (imageFile != null) {
        imagePath = imageFile.path;
        // Image will be uploaded during sync
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        entityType: 'menu_item',
        operation: 'CREATE',
        data: {
          'category_id': categoryId,
          'name': name,
          'price': price,
          'description': description ?? '',
          'is_veg': isVeg ? 1 : 0,
          'is_low_stock': isLowStock ? 1 : 0,
        },
        localImagePath: imagePath,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update menu item
  Future<bool> updateMenuItem({
    required int id,
    String? name,
    double? price,
    String? description,
    bool? isVeg,
    bool? isLowStock,
    File? imageFile,
  }) async {
    try {
      // Get existing item
      final existing = await _db.itemsDao.getById(id);
      if (existing == null) return false;

      // Update local DB
      await _db.itemsDao.update(
        MenuItemsCompanion(
          id: Value(id),
          name: name != null ? Value(name) : const Value.absent(),
          price: price != null ? Value(price) : const Value.absent(),
          description: description != null ? Value(description) : const Value.absent(),
          isVeg: isVeg != null ? Value(isVeg) : const Value.absent(),
          isLowStock: isLowStock != null ? Value(isLowStock) : const Value.absent(),
          synced: const Value(0),
        ),
      );

      // Handle image
      String? imagePath;
      if (imageFile != null) {
        imagePath = imageFile.path;
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        entityType: 'menu_item',
        operation: 'UPDATE',
        data: {
          if (name != null) 'name': name,
          if (price != null) 'price': price,
          if (description != null) 'description': description,
          if (isVeg != null) 'is_veg': isVeg ? 1 : 0,
          if (isLowStock != null) 'is_low_stock': isLowStock ? 1 : 0,
        },
        serverId: existing.serverId,
        localImagePath: imagePath,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update stock status
  Future<bool> updateStockStatus(int id, bool isLowStock) async {
    try {
      // Update local DB
      await _db.itemsDao.update(
        MenuItemsCompanion(
          id: Value(id),
          isLowStock: Value(isLowStock),
          synced: const Value(0),
        ),
      );

      // Get item for server ID
      final item = await _db.itemsDao.getById(id);

      // Add to sync queue
      if (item?.serverId != null) {
        await _syncService.addToSyncQueue(
          entityType: 'menu_item',
          operation: 'UPDATE',
          data: {'is_low_stock': isLowStock ? 1 : 0},
          serverId: item!.serverId,
        );

        // Trigger notification if low stock
        if (isLowStock) {
          // This would trigger FCM via API during sync
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete menu item
  Future<bool> deleteMenuItem(int id) async {
    try {
      // Get item for server ID
      final item = await _db.itemsDao.getById(id);
      
      // Delete from local DB
      await _db.itemsDao.deleteById(id);

      // Add to sync queue
      if (item?.serverId != null) {
        await _syncService.addToSyncQueue(
          entityType: 'menu_item',
          operation: 'DELETE',
          data: {},
          serverId: item!.serverId,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search items by name
  Future<List<MenuItem>> searchItems(String query) async {
    return await _db.itemsDao.search(query);
  }
}
