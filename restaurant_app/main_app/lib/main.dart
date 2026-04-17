import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'shared/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/sync/sync_service.dart';
import 'core/notifications/fcm_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/shell/main_shell.dart';

/// Main entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final db = AppDatabase();

  // Initialize API client
  final apiClient = ApiClient(baseUrl: kApiBaseUrl);

  // Initialize services
  final syncService = SyncService(db, apiClient);
  final fcmService = FCMService(db);
  final localNotifService = LocalNotifService(db);

  // Initialize notifications (non-blocking)
  fcmService.initialize().catchError((e) => print('FCM init error: $e'));
  localNotifService.initialize().catchError((e) => print('Local notif init error: $e'));

  // Start background sync
  syncService.startBackgroundSync();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(apiClient),
        syncServiceProvider.overrideWithValue(syncService),
      ],
      child: const RestaurantApp(),
    ),
  );
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppLauncher(),
    );
  }
}

/// Launches either login or main shell based on auth state
class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final db = ref.read(databaseProvider);
    final session = await db.sessionsDao.getActiveSession();
    
    setState(() {
      _isLoading = false;
      _isAuthenticated = session != null && session.expiresAt.isAfter(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return const MainShell();
    } else {
      return const LoginScreen();
    }
  }
}
