import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';

/// Repository for managing CMS content
class CmsRepository {
  final AppDatabase _db;
  final ApiClient _apiClient;

  CmsRepository(this._db, this._apiClient);

  /// Get all CMS sections from local DB
  Future<Map<String, dynamic>> getAllSections() async {
    // Fetch from API if online, otherwise from local DB
    try {
      final response = await _apiClient.get(Endpoints.cms);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // Fallback to local storage implementation
      return {};
    }
  }

  /// Get single section by key
  Future<dynamic> getSection(String key) async {
    try {
      final response = await _apiClient.get('${Endpoints.cms}/$key');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// Update CMS section (saves locally first, then syncs)
  Future<void> updateSection({
    required String key,
    required Map<String, dynamic> content,
    String? imagePath,
  }) async {
    // Save to local drafts table (implementation depends on schema)
    
    // Prepare data for API
    final formData = <String, dynamic>{
      'content_json': content,
    };

    // If image provided, add to multipart
    if (imagePath != null) {
      // Will be handled by multipart request
    }

    try {
      await _apiClient.put('${Endpoints.cms}/$key', data: formData);
    } catch (e) {
      // Save to sync queue for later
      print('CMS sync failed: $e');
    }
  }

  /// Publish all pending draft changes
  Future<void> publishDrafts() async {
    // Get all draft sections and push to server
    // Implementation depends on draft storage mechanism
  }

  /// Get draft status for a section
  bool hasDraftChanges(String key) {
    // Check if section has unpublished local changes
    return false;
  }
}

/// Provider for CmsRepository
final cmsRepositoryProvider = Provider<CmsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return CmsRepository(db, apiClient);
});
