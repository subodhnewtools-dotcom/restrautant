import 'dart:convert';
import '../../core/network/api_client.dart';

/// Menu Repository
/// Handles menu categories and items CRUD operations

class MenuRepository {
  final ApiClient _api = ApiClient();

  // ==================== Categories ====================

  /// Get all menu categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _api.get('/menu/categories');
      final data = jsonDecode(response.data.toString());
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String type,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _api.post(
        '/menu/categories',
        data: {'name': name, 'type': type, 'sort_order': sortOrder},
      );
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update category
  Future<Map<String, dynamic>> updateCategory({
    required int id,
    String? name,
    String? type,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final response = await _api.put(
        '/menu/categories/$id',
        data: {
          if (name != null) 'name': name,
          if (type != null) 'type': type,
          if (sortOrder != null) 'sort_order': sortOrder,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete category
  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await _api.delete('/menu/categories/$id');
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== Menu Items ====================

  /// Get menu items (optionally filtered by category)
  Future<List<Map<String, dynamic>>> getMenuItems({int? categoryId}) async {
    try {
      final response = await _api.get(
        '/menu/items',
        queryParameters: if (categoryId != null) {'category_id': categoryId},
      );
      final data = jsonDecode(response.data.toString());
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create new menu item with image upload
  Future<Map<String, dynamic>> createMenuItem({
    required String name,
    required int categoryId,
    required double price,
    String? description,
    bool isVeg = true,
    int sortOrder = 0,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'category_id': categoryId.toString(),
        'price': price.toString(),
        if (description != null) 'description': description,
        'is_veg': isVeg ? '1' : '0',
        'sort_order': sortOrder.toString(),
      });

      if (imagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }

      final response = await _api.upload('/menu/items', formData);
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update menu item
  Future<Map<String, dynamic>> updateMenuItem({
    required int id,
    String? name,
    int? categoryId,
    double? price,
    String? description,
    bool? isVeg,
    bool? isAvailable,
    int? sortOrder,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (name != null) 'name': name,
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (price != null) 'price': price.toString(),
        if (description != null) 'description': description,
        if (isVeg != null) 'is_veg': isVeg ? '1' : '0',
        if (isAvailable != null) 'is_available': isAvailable ? '1' : '0',
        if (sortOrder != null) 'sort_order': sortOrder.toString(),
      });

      if (imagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }

      final response = await _api.upload('/menu/items/$id', formData);
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete menu item
  Future<Map<String, dynamic>> deleteMenuItem(int id) async {
    try {
      final response = await _api.delete('/menu/items/$id');
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update stock status
  Future<Map<String, dynamic>> updateStockStatus({
    required int id,
    required bool isLowStock,
  }) async {
    try {
      final response = await _api.patch(
        '/menu/items/$id/stock',
        data: {'is_low_stock': isLowStock ? 1 : 0},
      );
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
