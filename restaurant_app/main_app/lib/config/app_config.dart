/// Central application configuration
/// All constants and configurable values are defined here

import 'package:flutter/foundation.dart';

class AppConfig {
  // API Configuration
  static const String kApiBaseUrl = 'http://localhost/restaurant_app/backend/api';
  
  // App Info
  static const String kAppName = 'Restaurant Manager';
  static const String kAppVersion = '1.0.0';
  
  // Sync Configuration
  static const int kSyncIntervalSecs = 300; // 5 minutes
  
  // Supported locales
  static const List<String> kSupportedLocales = ['en', 'hi'];
  static const String kDefaultLocale = 'en';
  
  // Theme Colors (matching backend CMS color_theme)
  static const int kPrimaryColorValue = 0xFFE8630A;   // Warm Orange
  static const int kSecondaryColorValue = 0xFF1E1E1E; // Charcoal
  static const int kBackgroundColorValue = 0xFFFFF8F2; // Soft Cream
  
  // File upload max size (must match backend UPLOAD_MAX_SIZE_MB)
  static const int kMaxUploadSizeMb = 5;
  
  // Notification topics
  static const String kFcmTopicAdminAlerts = 'admin_alerts';
  static const String kFcmTopicDailySummary = 'daily_summary';
  
  // Check if running on web
  static bool get isWeb => kIsWeb;
  
  // Check if running on Android
  static bool get isAndroid => !kIsWeb && const String.fromEnvironment('dart.vm.platform') == 'android';
  
  // Check if running on Windows
  static bool get isWindows => !kIsWeb && const String.fromEnvironment('dart.vm.platform') == 'windows';
}
