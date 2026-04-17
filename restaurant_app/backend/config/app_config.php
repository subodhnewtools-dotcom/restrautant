<?php
/**
 * Application Configuration
 * Update these values for your server environment
 */

// Base URL of your API (no trailing slash)
define('BASE_URL', 'http://localhost/restaurant_app/backend');

// JWT Secret - Generate a random 64-character string for production
define('JWT_SECRET', 'your-64-character-secret-key-here-replace-this-in-production');

// JWT token expiry in seconds (default: 24 hours)
define('TOKEN_EXPIRY', 86400);

// Firebase Cloud Messaging Server Key (from Firebase Console)
define('FCM_SERVER_KEY', 'your-fcm-server-key-here');

// Maximum upload file size in MB
define('UPLOAD_MAX_SIZE_MB', 5);

// Base path for uploads (relative to backend root)
define('UPLOAD_BASE_PATH', __DIR__ . '/uploads/');

// CORS allowed origins (comma-separated for multiple, or '*' for all in development)
define('CORS_ALLOWED_ORIGINS', '*');

// Environment: 'development' or 'production'
define('APP_ENV', 'development');

// Enable error display in development only
if (APP_ENV === 'development') {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}
