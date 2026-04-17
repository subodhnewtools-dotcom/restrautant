import 'dart:convert';
import '../../core/network/api_client.dart';

/// Authentication Repository
/// Handles login, logout, and session management

class AuthRepository {
  final ApiClient _api = ApiClient();

  /// Login with username and password
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.data.toString());
        if (data['success'] == true && data['data'] != null) {
          final token = data['data']['token'];
          final admin = data['data']['admin'];
          
          // Store token in API client
          _api.setAuthToken(token);
          
          return {
            'success': true,
            'token': token,
            'admin': admin,
          };
        }
      }
      
      return {
        'success': false,
        'error': data['message'] ?? 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Logout - revoke token
  Future<bool> logout() async {
    try {
      await _api.post('/auth/logout');
      _api.clearAuthToken();
      return true;
    } catch (e) {
      // Clear token anyway
      _api.clearAuthToken();
      return true;
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      final data = jsonDecode(response.data.toString());
      return {
        'success': data['success'] == true,
        'message': data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _api.isAuthenticated;
}
