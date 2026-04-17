import 'dart:convert';
import '../../core/network/api_client.dart';

/// CMS Repository
/// Handles content management sections for public web app

class CmsRepository {
  final ApiClient _api = ApiClient();

  /// Get all CMS sections (public)
  Future<Map<String, dynamic>> getAllSections() async {
    try {
      final response = await _api.get('/cms');
      final data = jsonDecode(response.data.toString());
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Get single CMS section by key (public)
  Future<Map<String, dynamic>?> getSection(String sectionKey) async {
    try {
      final response = await _api.get('/cms/$sectionKey');
      final data = jsonDecode(response.data.toString());
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update CMS section (admin only)
  Future<Map<String, dynamic>> updateSection({
    required String sectionKey,
    Map<String, dynamic>? content,
    List<String>? imagePaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (content != null) ...content,
      });

      // Handle multiple image uploads
      if (imagePaths != null) {
        for (int i = 0; i < imagePaths.length; i++) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(imagePaths[i]),
          ));
        }
      }

      final response = await _api.upload('/cms/$sectionKey', formData);
      return jsonDecode(response.data.toString());
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Helper method to get specific section types
  Future<Map<String, dynamic>?> getHeroBanner() => getSection('hero_banner');
  Future<Map<String, dynamic>?> getOffers() => getSection('offers');
  Future<Map<String, dynamic>?> getAboutUs() => getSection('about_us');
  Future<Map<String, dynamic>?> getGallery() => getSection('gallery');
  Future<Map<String, dynamic>?> getContact() => getSection('contact');
  Future<Map<String, dynamic>?> getSocialLinks() => getSection('social_links');
  Future<Map<String, dynamic>?> getMenuSettings() => getSection('menu_settings');
  Future<Map<String, dynamic>?> getColorTheme() => getSection('color_theme');
  Future<Map<String, dynamic>?> getSeo() => getSection('seo');
}
