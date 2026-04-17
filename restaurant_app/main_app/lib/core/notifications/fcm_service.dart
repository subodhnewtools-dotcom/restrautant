import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:io';

import '../database/app_database.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AppDatabase _db;

  FCMService(this._db);

  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Request permission
    await _requestPermissions();

    // Configure notification settings
    await _configureNotificationSettings();

    // Subscribe to topics
    await _subscribeToTopics();

    // Set up message handlers
    _setupMessageHandlers();
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    } else {
      print('User declined notification permissions');
    }
  }

  Future<void> _configureNotificationSettings() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
    try {
      await _messaging.subscribeToTopic('admin_alerts');
      await _messaging.subscribeToTopic('daily_summary');
      print('Subscribed to FCM topics');
    } catch (e) {
      print('Failed to subscribe to topics: $e');
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (requires top-level function)
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.data}');

    // Save to notifications log
    await _saveNotificationToLog(message);

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.data}');
    // Save to DB will happen when app starts
  }

  void _handleMessageTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Navigate based on payload
    final data = message.data;
    if (data.containsKey('type')) {
      // Handle navigation logic
    }
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
      presentSound: true,
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

  Future<void> _saveNotificationToLog(RemoteMessage message) async {
    final notifDao = _db.notificationsDao;
    
    await notifDao.insert(NotificationsLogCompanion.insert(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: jsonEncode(message.data),
      isRead: 0,
      receivedAt: DateTime.now(),
    ));
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // This must be a top-level function
    print('Handling background message: ${message.messageId}');
  }
}

class LocalNotifService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AppDatabase _db;

  LocalNotifService(this._db);

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
  }

  Future<void> showNotification({
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
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleDailySummary({
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Summary',
      channelDescription: 'Daily sales summary notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      0,
      'Daily Sales Summary',
      'View your daily sales report',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  DateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    return scheduledTime;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
