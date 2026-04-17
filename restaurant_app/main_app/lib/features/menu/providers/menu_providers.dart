import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_category_model.dart';
import '../models/menu_item_model.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';

class MenuRepository {
  final AppDatabase _db;
  final ApiClient _api;

  MenuRepository(this._db, this._api);

  // Categories
  Future<List<MenuCategoryModel>> getCategories() async {
    final local = await _db.menuCategoryDao.getAll();
    
    try {
      final response = await _api.get('/menu/categories');
      final List<dynamic> data = response.data['data'] ?? [];
      for (var item in data) {
        await _db.menuCategoryDao.upsert(MenuCategoryModel.fromMap(item));
      }
      return await _db.menuCategoryDao.getAll();
    } catch (_) {
      return local.map((e) => MenuCategoryModel.fromMap(e.toMap())).toList();
    }
  }

  Future<void> saveCategory({String? id, required String name, required bool isVeg}) async {
    final category = MenuCategoryModel(
      id: id,
      name: name,
      type: isVeg ? 'veg' : 'non-veg',
      isVeg: isVeg,
    );
    
    await _db.menuCategoryDao.upsert(category);
    
    await _db.syncQueueDao.insert({
      'table_name': 'menu_categories',
      'record_id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'action': id == null ? 'INSERT' : 'UPDATE',
      'data': JSON.stringify(category.toMap()),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    try {
      if (id == null) {
        await _api.post('/menu/categories', data: category.toMap());
      } else {
        await _api.put('/menu/categories/$id', data: category.toMap());
      }
    } catch (_) {}
  }

  Future<void> deleteCategory(String id) async {
    await _db.menuCategoryDao.delete(id);
    
    await _db.syncQueueDao.insert({
      'table_name': 'menu_categories',
      'record_id': id,
      'action': 'DELETE',
      'data': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    try {
      await _api.delete('/menu/categories/$id');
    } catch (_) {}
  }

  // Items
  Future<List<MenuItemModel>> getItems(String? categoryId) async {
    final local = categoryId == null 
        ? await _db.menuItemDao.getAll()
        : await _db.menuItemDao.getByCategory(categoryId);
    
    try {
      final url = categoryId != null 
          ? '/menu/items?category_id=$categoryId'
          : '/menu/items';
      final response = await _api.get(url);
      final List<dynamic> data = response.data['data'] ?? [];
      for (var item in data) {
        await _db.menuItemDao.upsert(MenuItemModel.fromMap(item));
      }
      return categoryId == null 
          ? await _db.menuItemDao.getAll()
          : await _db.menuItemDao.getByCategory(categoryId);
    } catch (_) {
      return local.map((e) => MenuItemModel.fromMap(e.toMap())).toList();
    }
  }

  MenuItemModel? getItemById(String id) {
    return _db.menuItemDao.getById(id);
  }

  Future<void> saveItem(MenuItemModel item, {dynamic imageFile}) async {
    await _db.menuItemDao.upsert(item);
    
    await _db.syncQueueDao.insert({
      'table_name': 'menu_items',
      'record_id': item.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'action': item.id == null ? 'INSERT' : 'UPDATE',
      'data': JSON.stringify(item.toMap()),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Image upload handled separately if needed
  }

  Future<void> deleteItem(String id) async {
    await _db.menuItemDao.delete(id);
    
    await _db.syncQueueDao.insert({
      'table_name': 'menu_items',
      'record_id': id,
      'action': 'DELETE',
      'data': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    try {
      await _api.delete('/menu/items/$id');
    } catch (_) {}
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final menuCategoriesProvider = FutureProvider<List<MenuCategoryModel>>((ref) async {
  return ref.read(menuRepositoryProvider).getCategories();
});

final menuItemsProvider = FutureProvider.family<List<MenuItemModel>, String?>((ref, categoryId) async {
  return ref.read(menuRepositoryProvider).getItems(categoryId);
});
