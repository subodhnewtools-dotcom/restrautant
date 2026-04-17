# Restaurant App — Deployment Guide

This guide provides step-by-step instructions to deploy the complete restaurant application from zero. Follow each step in order.

---

## Prerequisites

Ensure you have the following installed and configured before starting:

### Server Requirements
- **PHP 8.1+** with extensions: `pdo`, `pdo_mysql`, `gd`, `mbstring`, `json`
- **MySQL 8.0+** or MariaDB 10.6+
- **Apache 2.4+** with `mod_rewrite` enabled OR **Nginx** with rewrite rules
- **Composer** (latest stable version)
- SSH access to server with write permissions

### Development Machine Requirements
- **Flutter SDK 3.19+** (stable channel)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android builds)
- **Visual Studio Build Tools** with C++ workload (for Windows builds)
- **Git** for version control

### Third-Party Accounts
- **Firebase account** at [console.firebase.google.com](https://console.firebase.google.com)
- Domain name with SSL certificate (recommended for production)

---

## Part 1 — Backend Deployment

### Step 1: Upload Backend Files to Server

1. Connect to your server via FTP/SFTP or SSH.
2. Navigate to your web root directory (e.g., `/var/www/html` or `/public_html`).
3. Upload the entire contents of the `backend/` folder to the server.
4. Set correct permissions on the uploads directory:
   ```bash
   chmod -R 755 /path/to/backend/uploads
   chmod -R 755 /path/to/backend/uploads/food
   chmod -R 755 /path/to/backend/uploads/banners
   chmod -R 755 /path/to/backend/uploads/gallery
   chmod -R 755 /path/to/backend/uploads/logos
   ```
5. Ensure the web server user (often `www-data`) can write to these directories:
   ```bash
   chown -R www-data:www-data /path/to/backend/uploads
   ```

### Step 2: Create MySQL Database and Import Schema

1. Log into your MySQL server:
   ```bash
   mysql -u root -p
   ```
2. Create the database and user:
   ```sql
   CREATE DATABASE restaurant_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'restaurant_user'@'localhost' IDENTIFIED BY 'strong_password_here';
   GRANT ALL PRIVILEGES ON restaurant_db.* TO 'restaurant_user'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   ```
3. Import the schema file:
   ```bash
   mysql -u restaurant_user -p restaurant_db < /path/to/backend/config/schema.sql
   ```
   
   This creates all tables and inserts the default admin record.

### Step 3: Configure Backend Settings

1. Open `backend/config/database.php` in a text editor.
2. Update the following constants:
   ```php
   define('DB_HOST', 'localhost');        // or your DB host
   define('DB_NAME', 'restaurant_db');    // database name created above
   define('DB_USER', 'restaurant_user');  // database user created above
   define('DB_PASS', 'strong_password_here'); // database password
   define('DB_PORT', '3306');             // default MySQL port
   ```
3. Open `backend/config/app_config.php`.
4. Update the following constants:
   ```php
   define('BASE_URL', 'https://yourdomain.com');      // your domain
   define('JWT_SECRET', 'generate_64_char_random_string_here');
   define('TOKEN_EXPIRY', 604800);                     // 7 days in seconds
   define('FCM_SERVER_KEY', 'your_fcm_server_key');    // from Firebase (Part 5)
   define('UPLOAD_MAX_SIZE_MB', 5);
   define('UPLOAD_BASE_PATH', __DIR__ . '/../uploads/');
   ```
   
   To generate a random JWT secret:
   ```bash
   openssl rand -hex 32
   ```

### Step 4: Install PHP Dependencies

1. SSH into your server.
2. Navigate to the backend directory:
   ```bash
   cd /path/to/backend
   ```
3. Run Composer to install dependencies:
   ```bash
   composer install --no-dev --optimize-autoloader
   ```
   
   This installs `firebase/php-jwt` and any other required packages.

### Step 5: Configure Apache/Nginx Rewrites

#### For Apache:

1. Ensure `mod_rewrite` is enabled:
   ```bash
   sudo a2enmod rewrite
   sudo systemctl restart apache2
   ```
2. Verify that `.htaccess` files are allowed in your Apache configuration:
   ```apache
   <Directory /var/www/html>
       AllowOverride All
   </Directory>
   ```
3. The included `.htaccess` file will automatically route all `/api/*` requests to `index.php`.

#### For Nginx:

Add this location block to your server configuration:
```nginx
location /api {
    try_files $uri $uri/ /index.php?$query_string;
}

location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

### Step 6: Test API Endpoints

1. Test a public endpoint:
   ```bash
   curl https://yourdomain.com/api/menu/categories
   ```
   Expected response: `[]` (empty array) or JSON with categories if data exists.

2. Test login with default credentials:
   ```bash
   curl -X POST https://yourdomain.com/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"admin123"}'
   ```
   Expected response: JSON with `token` and `admin` object.

3. If both tests succeed, the backend is correctly configured.

---

## Part 2 — Flutter Web Build & Deployment

### Step 1: Build Flutter Web App

1. On your development machine, navigate to the Flutter project:
   ```bash
   cd /path/to/restaurant_app/main_app
   ```
2. Build the web release:
   ```bash
   flutter build web --release --base-href /
   ```
3. The build output will be in `main_app/build/web/`.

### Step 2: Deploy Web App to Server

1. Copy the contents of `build/web/` to the `backend/web_app/` directory on your server:
   ```bash
   scp -r main_app/build/web/* user@server:/path/to/backend/web_app/
   ```
   
   Or use FTP to upload all files.

### Step 3: Configure Web Server to Serve Web App

#### For Apache:

Update your virtual host configuration or `.htaccess` to serve `web_app/index.html` at the root:
```apache
DocumentRoot /path/to/backend/web_app

<Directory /path/to/backend/web_app>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Route API requests separately
RewriteEngine On
RewriteRule ^api(/.*)$ /path/to/backend/index.php [L,QSA]
```

#### For Nginx:

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    
    root /path/to/backend/web_app;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        alias /path/to/backend;
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### Step 4: Verify Web App

Open `https://yourdomain.com` in a browser. You should see the restaurant web app homepage with menu, offers, and other sections (may appear empty until CMS content is added via admin app).

---

## Part 3 — Flutter Android Build

### Step 1: Create Android Keystore

1. Generate a keystore for signing:
   ```bash
   keytool -genkey -v -keystore ~/restaurant-app-key.keystore -alias restaurant -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Fill in `android/key.properties` in the Flutter project:
   ```properties
   storePassword=<keystore-password>
   keyPassword=<key-password>
   keyAlias=restaurant
   storeFile=/home/username/restaurant-app-key.keystore
   ```

### Step 2: Configure Firebase for Android

1. Download `google-services.json` from Firebase Console (see Part 5).
2. Place it at `main_app/android/app/google-services.json`.

### Step 3: Build Release APK

1. Navigate to the Flutter project:
   ```bash
   cd /path/to/restaurant_app/main_app
   ```
2. Build the release APK:
   ```bash
   flutter build apk --release
   ```
3. The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Install and Test

1. Transfer the APK to an Android device.
2. Install and open the app.
3. Login with default credentials: `admin` / `admin123`.
4. Verify that menu, billing, and other features work correctly.

---

## Part 4 — Flutter Windows Build

### Step 1: Build Windows Executable

1. On a Windows machine (or cross-compile from Linux/macOS with appropriate toolchain):
   ```bash
   cd /path/to/restaurant_app/main_app
   flutter build windows --release
   ```
2. The build output will be in: `build/windows/x64/runner/Release/`

### Step 2: Distribute Windows App

The entire `Release/` folder must be distributed together, including:
- `restaurant_app.exe` (main executable)
- All `.dll` files
- `data/` folder with Flutter assets
- `flutter_windows.dll`

Create a ZIP archive and distribute to target machines. No installation required — run the `.exe` directly.

---

## Part 5 — Firebase Setup (Push Notifications)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com).
2. Click **Add Project**.
3. Enter project name (e.g., "Restaurant App").
4. Disable Google Analytics (optional).
5. Click **Create Project**.

### Step 2: Register Android App

1. In Firebase Console, click **Add App** → **Android**.
2. Enter Android package name: `com.restaurant.admin` (or your chosen package).
3. Download `google-services.json`.
4. Place the file at: `main_app/android/app/google-services.json`.

### Step 3: Get FCM Server Key

1. In Firebase Console, go to **Project Settings** (gear icon).
2. Go to the **Cloud Messaging** tab.
3. Copy the **Server Key** (also called Legacy Server Key).
4. Paste it into `backend/config/app_config.php`:
   ```php
   define('FCM_SERVER_KEY', 'AAAA...your-key-here...');
   ```

### Step 4: Enable Cloud Messaging API

1. Go to [Google Cloud Console](https://console.cloud.google.com).
2. Select your Firebase project.
3. Navigate to **APIs & Services** → **Library**.
4. Search for "Firebase Cloud Messaging API" and enable it.

### Step 5: Rebuild Android App

After adding `google-services.json`, rebuild the Android APK:
```bash
flutter build apk --release
```

### Step 6: Test Push Notifications

1. Login to the admin app on Android.
2. From the backend, send a test notification:
   ```bash
   curl -X POST https://yourdomain.com/api/notifications/send \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"topic":"admin_alerts","title":"Test","body":"Notification test"}'
   ```
3. The Android device should receive the push notification.

---

## Post-Deployment Checklist

- [ ] Backend API responds to all endpoints
- [ ] Default admin can login (`admin` / `admin123`)
- [ ] Web app loads at domain root
- [ ] Android app receives push notifications
- [ ] Image uploads work and files are accessible
- [ ] Sync works between admin app and server
- [ ] Change default admin password immediately

---

## Troubleshooting

### API Returns 404
- Check that `.htaccess` is uploaded and `mod_rewrite` is enabled.
- Verify `BASE_URL` in `app_config.php` matches your domain.

### Database Connection Failed
- Verify `database.php` credentials match your MySQL setup.
- Ensure MySQL user has privileges on the database.
- Check that MySQL is running and accepting connections.

### Images Not Uploading
- Verify `uploads/` directory permissions (755, owned by www-data).
- Check PHP `upload_max_filesize` and `post_max_size` in `php.ini`.
- Ensure GD extension is enabled in PHP.

### Push Notifications Not Working
- Verify `google-services.json` is in correct location.
- Check FCM Server Key in `app_config.php`.
- Ensure Firebase Cloud Messaging API is enabled.
- Rebuild Android app after adding Firebase config.

### Web App Shows Blank Page
- Check browser console for JavaScript errors.
- Verify `--base-href /` was used in build command.
- Ensure server serves `index.html` for all routes (SPA routing).

---

## Maintenance

### Backup Database
```bash
mysqldump -u restaurant_user -p restaurant_db > backup_$(date +%Y%m%d).sql
```

### Update Backend
1. Pull latest code from repository.
2. Run `composer install --no-dev --optimize-autoloader`.
3. Clear any opcode cache (if using OPcache).

### Update Flutter App
1. Increment version in `pubspec.yaml`.
2. Rebuild APK/Windows executable.
3. Distribute to devices.

### Monitor Logs
Check Apache/Nginx error logs and PHP error logs regularly:
```bash
tail -f /var/log/apache2/error.log
tail -f /var/log/php8.1-fpm.log
```
