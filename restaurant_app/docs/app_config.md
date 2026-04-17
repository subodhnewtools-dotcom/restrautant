# Restaurant App — Configuration Guide

This document lists every configurable value in the application and exactly where to change it. Use this guide when setting up the app for a new restaurant.

---

## Section 1 — Backend Configuration

### File: `backend/config/database.php`

This file contains all database connection settings.

```php
<?php
define('DB_HOST', 'localhost');      // MySQL server hostname or IP
define('DB_NAME', 'restaurant_db');  // Database name
define('DB_USER', 'restaurant_user');// Database username
define('DB_PASS', 'your_password');  // Database password
define('DB_PORT', '3306');           // MySQL port (default: 3306)
define('DB_CHARSET', 'utf8mb4');     // Character set (do not change)
```

**When to change:**
- After creating the MySQL database and user (Part 1 of deployment).
- If moving to a different database server.

---

### File: `backend/config/app_config.php`

This file contains all application-wide constants.

```php
<?php
// Base URL of your API (no trailing slash)
define('BASE_URL', 'https://yourdomain.com');

// JWT secret key (64-character random string)
// Generate with: openssl rand -hex 32
define('JWT_SECRET', 'your_64_char_random_secret_here');

// Token expiry in seconds (default: 7 days)
define('TOKEN_EXPIRY', 604800);

// Firebase Cloud Messaging Server Key (from Firebase Console)
define('FCM_SERVER_KEY', 'AAAA...your_fcm_server_key...');

// Maximum upload file size in megabytes
define('UPLOAD_MAX_SIZE_MB', 5);

// Absolute path to uploads directory (do not change unless moving folders)
define('UPLOAD_BASE_PATH', __DIR__ . '/../uploads/');

// CORS allowed origins (comma-separated for multiple domains)
define('CORS_ALLOWED_ORIGINS', '*'); // Change to specific domain in production

// Timezone for date functions
define('APP_TIMEZONE', 'UTC'); // Change to your local timezone, e.g., 'Asia/Kolkata'
```

**When to change:**
- `BASE_URL`: Set during initial deployment.
- `JWT_SECRET`: Set during initial deployment (generate once, never change).
- `FCM_SERVER_KEY`: Add after setting up Firebase (Part 5 of deployment).
- `CORS_ALLOWED_ORIGINS`: Change from `*` to your specific domain in production.
- `APP_TIMEZONE`: Set to your restaurant's local timezone.

---

## Section 2 — Flutter App Configuration

### File: `main_app/lib/config/app_config.dart`

This file contains all Flutter app configuration constants.

```dart
class AppConfig {
  // Backend API base URL (must match BASE_URL in backend)
  static const String kApiBaseUrl = 'https://yourdomain.com/api';
  
  // App display name
  static const String kAppName = 'Restaurant Admin';
  
  // Sync interval in seconds (how often to auto-sync with server)
  static const int kSyncIntervalSecs = 300; // 5 minutes
  
  // Supported locales for multi-language support
  static const List<Locale> kSupportedLocales = [
    Locale('en'),      // English
    Locale('hi'),      // Hindi
    // Add more as needed: Locale('es'), Locale('fr'), etc.
  ];
  
  // Default locale
  static const Locale kDefaultLocale = Locale('en');
  
  // Connection timeout in seconds
  static const int kConnectionTimeoutSecs = 30;
  
  // Receive timeout in seconds
  static const int kReceiveTimeoutSecs = 30;
}
```

**When to change:**
- `kApiBaseUrl`: Set to match your backend `BASE_URL` (add `/api` suffix).
- `kAppName`: Change to your restaurant's admin app name.
- `kSupportedLocales`: Add or remove languages based on your needs.
- `kSyncIntervalSecs`: Adjust based on how frequently you want background sync.

---

## Section 3 — App Logo & Branding

### App Logo (Mobile - Android)

1. Prepare your logo image:
   - Format: PNG with transparent background
   - Size: 512×512 pixels
   - Location: `main_app/assets/images/app_logo.png`

2. Replace the placeholder image at that path.

3. Update `pubspec.yaml` flutter_launcher_icons configuration:
   ```yaml
   flutter_launcher_icons:
     android: true
     image_path: "assets/images/app_logo.png"
     adaptive_icon_foreground: "assets/images/app_logo_foreground.png"
     adaptive_icon_background: "#E8630A"
   ```

4. Run the launcher icon generator:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### App Logo (Windows)

1. Prepare your icon file:
   - Format: ICO (multi-size)
   - Sizes included: 16×16, 32×32, 48×48, 256×256
   - Location: `main_app/windows/runner/resources/app_icon.ico`

2. Replace the `.ico` file at that path.

3. Rebuild Windows app:
   ```bash
   flutter build windows --release
   ```

### Splash Screen Logo

1. Prepare splash logo:
   - Format: PNG
   - Size: 1024×1024 pixels recommended
   - Location: `main_app/assets/images/splash_logo.png`

2. Replace the image at that path.

3. Update `pubspec.yaml` flutter_native_splash configuration:
   ```yaml
   flutter_native_splash:
     color: "#FFF8F2"
     image: assets/images/splash_logo.png
     web: true
     android: true
     windows: true
   ```

4. Run the splash screen generator:
   ```bash
   flutter pub run flutter_native_splash:create
   ```

### Web Favicon

1. Prepare favicon:
   - Format: PNG
   - Size: 512×512 pixels
   - Location: `main_app/web/favicon.png`

2. Replace the image at that path.

3. Rebuild web app:
   ```bash
   flutter build web --release
   ```

---

## Section 4 — Color Theme

### File: `main_app/lib/shared/theme/app_theme.dart`

All app colors are defined at the top of this file. Changing these values automatically updates the entire app theme.

```dart
class AppColors {
  // Primary brand color (used for buttons, highlights, accents)
  static const Color kPrimaryColor = Color(0xFFE8630A);      // Warm Orange
  
  // Secondary color (used for secondary actions, backgrounds)
  static const Color kSecondaryColor = Color(0xFF1E1E1E);    // Charcoal
  
  // Main background color
  static const Color kBackgroundColor = Color(0xFFFFF8F2);   // Soft Cream
  
  // Card and surface background color
  static const Color kSurfaceColor = Color(0xFFFFFFFF);      // White
  
  // Success state color (veg indicator, positive actions)
  static const Color kSuccessColor = Color(0xFF43A047);      // Veg Green
  
  // Danger/error color (non-veg indicator, destructive actions)
  static const Color kDangerColor = Color(0xFFE53935);       // Non-Veg Red
  
  // Primary text color
  static const Color kTextPrimary = Color(0xFF212121);       // Dark Gray
  
  // Secondary text color (hints, subtitles)
  static const Color kTextSecondary = Color(0xFF757575);     // Medium Gray
  
  // Divider and border color
  static const Color kDividerColor = Color(0xFFE0E0E0);      // Light Gray
  
  // Disabled state color
  static const Color kDisabledColor = Color(0xFFBDBDBD);     // Light Gray
  
  // Warning color
  static const Color kWarningColor = Color(0xFFFFA000);      // Amber
}
```

**When to change:**
- To match your restaurant's brand colors.
- All UI elements using these colors will update automatically.
- Rebuild the app after changes.

---

## Section 5 — Admin Credentials

### Default Admin Account

After importing `schema.sql`, the following admin account exists:

- **Username:** `admin`
- **Password:** `admin123`

### Change Password via App (Recommended)

1. Login to admin app with default credentials.
2. Navigate to **Settings** → **Admin Profile**.
3. Tap **Change Password**.
4. Enter current password, then new password twice.
5. Save.

### Change Password via MySQL (If Locked Out)

Run this SQL command to reset the admin password:

```sql
UPDATE admins 
SET password = SHA2('your_new_password', 256) 
WHERE username = 'admin';
```

Replace `'your_new_password'` with your desired password.

### Create Additional Admin Users

```sql
INSERT INTO admins (username, password, full_name, email, created_at)
VALUES (
  'new_admin',
  SHA2('password123', 256),
  'Admin Full Name',
  'admin@example.com',
  UNIX_TIMESTAMP()
);
```

---

## Section 6 — Translations

### Translation Files Location

Translation files are stored in: `main_app/assets/translations/`

Required file: `en.json` (English)
Optional files: `hi.json`, `es.json`, `fr.json`, etc.

### Adding a New Language

1. Copy `en.json` to a new file with BCP47 locale code:
   ```bash
   cp main_app/assets/translations/en.json main_app/assets/translations/es.json
   ```

2. Translate all values (keep keys unchanged):
   
   **en.json:**
   ```json
   {
     "app_name": "Restaurant Admin",
     "login_title": "Login",
     "username_hint": "Username",
     "password_hint": "Password",
     "login_button": "Sign In"
   }
   ```
   
   **es.json:**
   ```json
   {
     "app_name": "Administrador de Restaurante",
     "login_title": "Acceso",
     "username_hint": "Nombre de usuario",
     "password_hint": "Contraseña",
     "login_button": "Iniciar sesión"
   }
   ```

3. Add the locale to `kSupportedLocales` in `app_config.dart`:
   ```dart
   static const List<Locale> kSupportedLocales = [
     Locale('en'),
     Locale('hi'),
     Locale('es'),  // Add this line
   ];
   ```

4. Rebuild the app:
   ```bash
   flutter build web --release    # For web
   flutter build apk --release    # For Android
   ```

### Using Translations in Code

```dart
// In widgets:
Text(context.t('app_name'))

// Or with parameters:
Text(context.t('welcome_message', {'name': userName}))
```

---

## Section 7 — Push Notification Topics

### Default Topics

The Android app automatically subscribes to these FCM topics on login:

- `'admin_alerts'` — For low stock alerts, order notifications, urgent updates
- `'daily_summary'` — For daily sales summary notifications

### Sending Notifications to Topics

Use the `/api/notifications/send` endpoint:

```bash
curl -X POST https://yourdomain.com/api/notifications/send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "admin_alerts",
    "title": "Low Stock Alert",
    "body": "Item \"Paneer Tikka\" is running low on stock."
  }'
```

### Custom Topics

To add custom topics:

1. Modify `fcm_service.dart` to subscribe to additional topics on login:
   ```dart
   await FirebaseMessaging.instance.subscribeToTopic('custom_topic');
   ```

2. Send notifications to the new topic via the API.

---

## Section 8 — Printer Configuration

### Bluetooth Printer (Android)

Printers are configured via the app interface:

1. Open admin app on Android.
2. Go to **Settings** → **Printer Management**.
3. Tap **Scan for Printers**.
4. Select your printer from the list.
5. The printer address is saved to the `printer_config` table.

### Manual Printer Configuration (Advanced)

Directly insert into database:

```sql
INSERT INTO printer_config (id, device_address, device_name, printer_type, is_default)
VALUES (1, '00:11:22:33:44:55', 'Bluetooth Printer', 'bluetooth', 1);
```

### Windows Printer

Windows printers are selected at print time via the system print dialog. No configuration needed.

---

## Section 9 — Image Upload Settings

### File: `backend/config/app_config.php`

```php
define('UPLOAD_MAX_SIZE_MB', 5);  // Maximum file size in MB
```

### PHP Configuration (`php.ini`)

Ensure these values match or exceed your upload settings:

```ini
upload_max_filesize = 5M
post_max_size = 6M
max_file_uploads = 20
```

### Image Compression Settings

Image compression happens in the Flutter app before upload:

- Food images: Compressed to 80% quality, max 1024px width
- Logo images: Compressed to 90% quality, max 512px width
- Banner images: Compressed to 75% quality, max 1920px width

To adjust compression, modify `flutter_image_compress` parameters in the respective editor screens.

---

## Section 10 — Session & Security Settings

### Token Expiry

File: `backend/config/app_config.php`

```php
define('TOKEN_EXPIRY', 604800);  // 7 days in seconds
```

Common values:
- 1 day: `86400`
- 7 days: `604800`
- 30 days: `2592000`

### JWT Secret Rotation (Advanced)

⚠️ **Warning:** Changing the JWT secret will invalidate all existing sessions. All users will need to login again.

1. Generate new secret:
   ```bash
   openssl rand -hex 32
   ```

2. Update `JWT_SECRET` in `backend/config/app_config.php`.

3. Clear the `token_blacklist` table (optional):
   ```sql
   TRUNCATE TABLE token_blacklist;
   ```

---

## Section 11 — Environment-Specific Configuration

### Development Environment

For local development, create environment-specific config files:

**`backend/config/database.dev.php`:**
```php
<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'restaurant_dev');
define('DB_USER', 'root');
define('DB_PASS', '');
```

**`main_app/lib/config/app_config.dev.dart`:**
```dart
class AppConfig {
  static const String kApiBaseUrl = 'http://localhost:8080/api';
  // ... other settings
}
```

Use Flutter flavors or manual switching for different environments.

---

## Quick Reference Table

| Setting | File | Default Value | Change Frequency |
|---------|------|---------------|------------------|
| Database Host | `backend/config/database.php` | `localhost` | Once |
| Database Name | `backend/config/database.php` | `restaurant_db` | Once |
| API Base URL | `backend/config/app_config.php` | (empty) | Once |
| JWT Secret | `backend/config/app_config.php` | (empty) | Once (never change) |
| FCM Server Key | `backend/config/app_config.php` | (empty) | Once |
| App Name | `main_app/lib/config/app_config.dart` | `Restaurant Admin` | Once |
| Primary Color | `main_app/lib/shared/theme/app_theme.dart` | `#E8630A` | Per branding |
| Supported Languages | `main_app/lib/config/app_config.dart` | `[en, hi]` | As needed |
| Sync Interval | `main_app/lib/config/app_config.dart` | `300s` | Rarely |
| Admin Password | MySQL `admins` table | `admin123` | Immediately after deploy |

---

## Checklist for New Restaurant Setup

- [ ] Update `backend/config/database.php` with DB credentials
- [ ] Update `backend/config/app_config.php` with BASE_URL and JWT_SECRET
- [ ] Import `backend/config/schema.sql` into MySQL
- [ ] Generate and set FCM Server Key
- [ ] Update `main_app/lib/config/app_config.dart` with API URL
- [ ] Replace app logo images (Android, Windows, splash, favicon)
- [ ] Update color theme in `app_theme.dart` to match branding
- [ ] Change default admin password
- [ ] Add translation files if multi-language needed
- [ ] Configure printer (Android only)
- [ ] Test all features end-to-end
