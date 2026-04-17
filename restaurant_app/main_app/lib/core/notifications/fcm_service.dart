import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../database/app_database.dart';

class FCMService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AppDatabase _db;
  
  // Firebase messaging instance (only used on Android)
  dynamic? _messaging;

  FCMService(this._db);

  Future<void> initialize() async {
    // Firebase is only available on Android
    if (!kIsWeb && Platform.isAndroid) {
      try {
        // Initialize Firebase and messaging
        await _initializeFirebase();
        
        if (_messaging != null) {
          // Request permission
          await _requestPermissions();

          // Configure notification settings
          await _configureNotificationSettings();

          // Subscribe to topics
          await _subscribeToTopics();

          // Set up message handlers
          _setupMessageHandlers();
        } else {
          // Fallback to local notifications only
          await _configureNotificationSettings();
          print('Firebase messaging not available, using local notifications only');
        }
      } catch (e) {
        print('FCM initialization failed: $e');
        // Continue with local notifications only
        await _configureNotificationSettings();
      }
    } else {
      // Web or Windows - only setup local notifications
      await _configureNotificationSettings();
      print('FCM not available on this platform, using local notifications only');
    }
  }

  Future<void> _initializeFirebase() async {
    // Firebase is only available on Android - skip on Windows/Web
    // This method is a placeholder since we removed Firebase dependencies
    print('Firebase initialization skipped - not available on this platform');
    _messaging = null;
  }

  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    
    try {
      // This would request FCM permissions on Android
      print('FCM permissions requested');
    } catch (e) {
      print('Failed to request FCM permissions: $e');
    }
  }

  Future<void> _configureNotificationSettings() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _subscribeToTopics() async {
    if (_messaging == null) {
      print('FCM topics subscription skipped - messaging not available');
      return;
    }
    
    try {
      // This would subscribe to FCM topics on Android
      print('Would subscribe to FCM topics: admin_alerts, daily_summary');
    } catch (e) {
      print('Failed to subscribe to topics: $e');
    }
  }

  void _setupMessageHandlers() {
    // FCM message handlers only work on Android with Firebase
    // Skip on Windows/Web
    if (_messaging == null) {
      print('FCM message handlers skipped - messaging not available');
      return;
    }
    
    // Handle foreground messages
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (requires top-level function)
    // FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  // FCM message handlers - only used on Android with Firebase
  // These are kept for future Android implementation
  
  Future<void> _handleForegroundMessage(dynamic message) async {
    print('Received foreground message');
    // Implementation for Android only
  }

  Future<void> _handleBackgroundMessage(dynamic message) async {
    print('Received background message');
    // Implementation for Android only
  }

  void _handleMessageTap(dynamic message) {
    print('Notification tapped');
    // Implementation for Android only
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      // Handle navigation logic
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'restaurant_channel',
      'Restaurant Notifications',
      channelDescription: 'Notifications for restaurant admin',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _saveNotificationToLog(dynamic message) async {
    // FCM notifications are only available on Android
    // This is a placeholder for future implementation
    print('Notification logging skipped - FCM not available');
  }

  Future<String?> getToken() async {
    if (_messaging == null) return null;
    // Would return FCM token on Android
    return null;
  }

  Future<void> deleteToken() async {
    if (_messaging == null) return;
    // Would delete FCM token on Android
  }

  static Future<void> _handleBackgroundMessage(dynamic message) async {
    // This must be a top-level function
    // Placeholder for Android implementation
    print('Background message handler (Android only)');
  }
}
