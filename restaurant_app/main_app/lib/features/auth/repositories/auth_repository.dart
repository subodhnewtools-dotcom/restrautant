import 'package:drift/drift.dart';

/// Authentication repository - handles all auth operations
class AuthRepository {
  final AppDatabase _db;
  final ApiClient _apiClient;

  AuthRepository(this._db, this._apiClient);

  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    try {
      // Call API
      final response = await _apiClient.post('/auth/login', {
        'username': username,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      
      // Save session to local DB
      final session = AdminSessionsCompanion.insert(
        adminId: data['admin']['id'],
        username: data['admin']['username'],
        email: data['admin']['email'] ?? '',
        token: data['token'],
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        isActive: 1,
      );

      await _db.sessionsDao.upsert(session);

      return AuthResult(
        success: true,
        admin: AdminProfile(
          id: data['admin']['id'],
          username: data['admin']['username'],
          email: data['admin']['email'] ?? '',
        ),
      );
    } on ApiException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logout current session
  Future<bool> logout() async {
    try {
      // Get current session
      final session = await _db.sessionsDao.getActiveSession();
      
      if (session != null) {
        // Call API to blacklist token
        await _apiClient.post('/auth/logout', {});
        
        // Clear local session
        await _db.sessionsDao.clearAllSessions();
      }

      return true;
    } catch (e) {
      // Clear local session even if API call fails
      await _db.sessionsDao.clearAllSessions();
      return true;
    }
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post('/auth/change-password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

      return AuthResult(success: true);
    } on ApiException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Password change failed: ${e.toString()}',
      );
    }
  }

  /// Get active session from local DB
  Future<AdminSession?> getActiveSession() async {
    return await _db.sessionsDao.getActiveSession();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final session = await getActiveSession();
    return session != null && session.expiresAt.isAfter(DateTime.now());
  }
}

class AuthResult {
  final bool success;
  final AdminProfile? admin;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.admin,
    this.errorMessage,
  });
}

class AdminProfile {
  final int id;
  final String username;
  final String email;

  AdminProfile({
    required this.id,
    required this.username,
    required this.email,
  });
}
