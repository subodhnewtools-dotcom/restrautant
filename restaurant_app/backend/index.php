<?php
/**
 * API Router / Entry Point
 * Routes all API requests to appropriate handlers
 */

// Load configuration
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/app_config.php';

// Load core classes
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/core/Response.php';
require_once __DIR__ . '/core/Auth.php';
require_once __DIR__ . '/core/FileUpload.php';

// Set CORS headers
header('Access-Control-Allow-Origin: ' . CORS_ALLOWED_ORIGINS);
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get request URI and method
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Remove query string
$basePath = parse_url(BASE_URL, PHP_URL_PATH) ?: '';
$path = str_replace($basePath, '', strtok($requestUri, '?'));

// Remove /api prefix if present
$path = preg_replace('#^/api#', '', $path);

// Parse path segments
$segments = array_values(array_filter(explode('/', $path)));

// Route mapping
$routes = [
    // Auth routes
    ['POST', ['auth', 'login'], 'api/auth/login.php'],
    ['POST', ['auth', 'logout'], 'api/auth/logout.php', true],
    ['POST', ['auth', 'change-password'], 'api/auth/change_password.php', true],
    
    // Menu categories
    ['GET', ['menu', 'categories'], 'api/menu/categories.php'],
    ['POST', ['menu', 'categories'], 'api/menu/categories.php', true],
    ['PUT', ['menu', 'categories', '*'], 'api/menu/categories.php', true],
    ['DELETE', ['menu', 'categories', '*'], 'api/menu/categories.php', true],
    
    // Menu items
    ['GET', ['menu', 'items'], 'api/menu/items.php'],
    ['POST', ['menu', 'items'], 'api/menu/items.php', true],
    ['PUT', ['menu', 'items', '*'], 'api/menu/items.php', true],
    ['DELETE', ['menu', 'items', '*'], 'api/menu/items.php', true],
    ['PATCH', ['menu', 'items', '*', 'stock'], 'api/menu/items.php', true],
    
    // Billing templates
    ['GET', ['billing', 'templates'], 'api/billing/templates.php', true],
    ['POST', ['billing', 'templates'], 'api/billing/templates.php', true],
    ['PUT', ['billing', 'templates', '*'], 'api/billing/templates.php', true],
    ['DELETE', ['billing', 'templates', '*'], 'api/billing/templates.php', true],
    
    // Bills
    ['GET', ['billing', 'bills'], 'api/billing/bills.php', true],
    ['GET', ['billing', 'bills', '*'], 'api/billing/bills.php', true],
    ['POST', ['billing', 'bills'], 'api/billing/bills.php', true],
    ['DELETE', ['billing', 'bills', '*'], 'api/billing/bills.php', true],
    
    // Messages
    ['GET', ['messages'], 'api/messages/messages.php', true],
    ['POST', ['messages'], 'api/messages/messages.php', true],
    ['PUT', ['messages', '*'], 'api/messages/messages.php', true],
    ['DELETE', ['messages', '*'], 'api/messages/messages.php', true],
    
    // CMS
    ['GET', ['cms'], 'api/cms/cms.php'],
    ['GET', ['cms', '*'], 'api/cms/cms.php'],
    ['PUT', ['cms', '*'], 'api/cms/cms.php', true],
    
    // Feedback
    ['GET', ['feedback'], 'api/feedback/feedback.php', true],
    ['POST', ['feedback'], 'api/feedback/feedback.php'],
    ['DELETE', ['feedback', '*'], 'api/feedback/feedback.php', true],
    
    // Notifications
    ['POST', ['notifications', 'send'], 'api/notifications/notify.php', true],
    
    // Sync
    ['GET', ['sync', 'full_sync'], 'api/sync/full_sync.php', true],
];

// Find matching route
$matchedRoute = null;
$routeParams = [];

foreach ($routes as $route) {
    [$method, $routePath, $handler, $requiresAuth] = array_pad($route, 4, false);
    
    if ($method !== $requestMethod) {
        continue;
    }
    
    // Check if path matches
    $match = true;
    $routeParams = [];
    
    foreach ($routePath as $index => $segment) {
        if (!isset($segments[$index])) {
            $match = false;
            break;
        }
        
        if ($segment === '*') {
            $routeParams['id'] = $segments[$index];
        } elseif ($segment !== $segments[$index]) {
            $match = false;
            break;
        }
    }
    
    // Ensure exact match (no extra segments)
    if ($match && count($segments) === count($routePath)) {
        $matchedRoute = $route;
        break;
    }
}

// Handle 404
if (!$matchedRoute) {
    Response::notFound('Endpoint not found: ' . $requestMethod . ' ' . $path);
}

// Extract handler details
[, , $handler, $requiresAuth] = $matchedRoute;

// Require authentication if needed
if ($requiresAuth) {
    Auth::requireAuth();
}

// Include and execute handler
$handlerPath = __DIR__ . '/' . $handler;

if (!file_exists($handlerPath)) {
    Response::serverError('Handler not found: ' . $handler);
}

require $handlerPath;
