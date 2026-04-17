<?php
/**
 * POST /api/auth/logout
 * Revoke JWT token by adding to blacklist
 */

$adminId = Auth::requireAuth();
$token = Auth::getTokenFromRequest();

if (!$token) {
    Response::unauthorized('Token not found');
}

// Get token payload to find expiration
$payload = Auth::verifyToken($token);

if (!$payload) {
    Response::unauthorized('Invalid token');
}

// Add token to blacklist
Auth::blacklistToken($token, $payload['exp']);

Response::success(null, 'Logout successful');
