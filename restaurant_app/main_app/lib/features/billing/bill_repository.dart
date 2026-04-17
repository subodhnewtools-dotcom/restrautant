import 'dart:convert';
import '../../core/network/api_client.dart';

/// Billing Repository
/// Handles bill templates and bills CRUD operations

class BillRepository {
  final ApiClient _api = ApiClient();

  // ==================== Bill Templates ====================

  /// Get all bill templates
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await _api.get('/billing/templates');
      final data = jsonDecode(response.data.toString());
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create new bill template
  Future<Map<String, dynamic>> createTemplate({
    required String name,
    required String brandName,
    String? footerText,
    String? logoPath,
    String fontStyle = 'Arial',
    String primaryColor = '#E8630A',
    bool isDefault = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'brand_name': brandName,
        if (footerText != null) 'footer_text': footerText,
        'font_style': fontStyle,
        'primary_color': primaryColor,
        'is_default': isDefault ? '1' : '0',
      });

      if (logoPath != null) {
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(logoPath),
        ));
      }

      final response = await _api.upload('/billing/templates', formData);
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update bill template
  Future<Map<String, dynamic>> updateTemplate({
    required int id,
    String? name,
    String? brandName,
    String? footerText,
    String? logoPath,
    String? fontStyle,
    String? primaryColor,
    bool? isDefault,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (name != null) 'name': name,
        if (brandName != null) 'brand_name': brandName,
        if (footerText != null) 'footer_text': footerText,
        if (fontStyle != null) 'font_style': fontStyle,
        if (primaryColor != null) 'primary_color': primaryColor,
        if (isDefault != null) 'is_default': isDefault ? '1' : '0',
      });

      if (logoPath != null) {
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(logoPath),
        ));
      }

      final response = await _api.upload('/billing/templates/$id', formData);
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete bill template
  Future<Map<String, dynamic>> deleteTemplate(int id) async {
    try {
      final response = await _api.delete('/billing/templates/$id');
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== Bills ====================

  /// Get all bills with optional date filters
  Future<List<Map<String, dynamic>>> getBills({
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _api.get(
        '/billing/bills',
        queryParameters: {
          if (date != null) 'date': date,
          if (fromDate != null) 'from': fromDate,
          if (toDate != null) 'to': toDate,
        },
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

  /// Get single bill by ID
  Future<Map<String, dynamic>?> getBill(int id) async {
    try {
      final response = await _api.get('/billing/bills/$id');
      final data = jsonDecode(response.data.toString());
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create new bill
  Future<Map<String, dynamic>> createBill({
    String? customerName,
    String? customerPhone,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    String? discountType,
    double discountValue = 0,
    required double total,
    int? templateId,
  }) async {
    try {
      final response = await _api.post(
        '/billing/bills',
        data: {
          if (customerName != null) 'customer_name': customerName,
          if (customerPhone != null) 'customer_phone': customerPhone,
          'items': items,
          'subtotal': subtotal,
          if (discountType != null) 'discount_type': discountType,
          'discount_value': discountValue,
          'total': total,
          if (templateId != null) 'template_id': templateId,
        },
      );
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete bill
  Future<Map<String, dynamic>> deleteBill(int id) async {
    try {
      final response = await _api.delete('/billing/bills/$id');
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
