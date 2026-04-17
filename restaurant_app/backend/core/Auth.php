<?php
/**
 * JWT Authentication Handler
 * Token generation, verification, and validation
 */

class Auth {
    /**
     * Generate JWT token for admin
     * 
     * @param int $adminId Admin user ID
     * @return string JWT token
     */
    public static function generateToken(int $adminId): string {
        $header = [
            'alg' => 'HS256',
            'typ' => 'JWT'
        ];
        
        $payload = [
            'iss' => BASE_URL,
            'sub' => $adminId,
            'iat' => time(),
            'exp' => time() + TOKEN_EXPIRY
        ];
        
        $base64Header = self::base64UrlEncode(json_encode($header));
        $base64Payload = self::base64UrlEncode(json_encode($payload));
        $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
        $base64Signature = self::base64UrlEncode($signature);
        
        return "$base64Header.$base64Payload.$base64Signature";
    }
    
    /**
     * Verify JWT token and return payload
     * 
     * @param string $token JWT token
     * @return array|null Decoded payload or null if invalid
     */
    public static function verifyToken(string $token): ?array {
        $parts = explode('.', $token);
        
        if (count($parts) !== 3) {
            return null;
        }
        
        [$base64Header, $base64Payload, $base64Signature] = $parts;
        
        // Decode header and payload
        $header = json_decode(self::base64UrlDecode($base64Header), true);
        $payload = json_decode(self::base64UrlDecode($base64Payload), true);
        
        if (!$header || !$payload) {
            return null;
        }
        
        // Verify algorithm
        if (!isset($header['alg']) || $header['alg'] !== 'HS256') {
            return null;
        }
        
        // Verify signature
        $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
        $base64SignatureExpected = self::base64UrlEncode($signature);
        
        if (!hash_equals($base64SignatureExpected, $base64Signature)) {
            return null;
        }
        
        // Check expiration
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return null;
        }
        
        // Check if token is blacklisted
        if (self::isTokenBlacklisted($token)) {
            return null;
        }
        
        return $payload;
    }
    
    /**
     * Require authentication for API endpoint
     * Returns admin ID if valid, sends 401 response if invalid
     * 
     * @return int Admin user ID
     */
    public static function requireAuth(): int {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        
        if (empty($authHeader)) {
            Response::unauthorized('Authorization header missing');
        }
        
        if (!preg_match('/Bearer\s+(.+)$/i', $authHeader, $matches)) {
            Response::unauthorized('Invalid authorization format. Use: Bearer <token>');
        }
        
        $token = $matches[1];
        $payload = self::verifyToken($token);
        
        if ($payload === null) {
            Response::unauthorized('Invalid or expired token');
        }
        
        return (int)$payload['sub'];
    }
    
    /**
     * Get token from request headers
     * 
     * @return string|null Token or null if not present
     */
    public static function getTokenFromRequest(): ?string {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        
        if (preg_match('/Bearer\s+(.+)$/i', $authHeader, $matches)) {
            return $matches[1];
        }
        
        return null;
    }
    
    /**
     * Check if token is blacklisted
     * 
     * @param string $token JWT token
     * @return bool True if blacklisted
     */
    private static function isTokenBlacklisted(string $token): bool {
        try {
            $tokenHash = hash('sha256', $token);
            
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare("SELECT id FROM token_blacklist WHERE token_hash = ? AND expires_at > NOW()");
            $stmt->execute([$tokenHash]);
            
            return $stmt->fetch() !== false;
        } catch (PDOException $e) {
            return false;
        }
    }
    
    /**
     * Add token to blacklist
     * 
     * @param string $token JWT token
     * @param int $expiresAt Expiration timestamp
     * @return void
     */
    public static function blacklistToken(string $token, int $expiresAt): void {
        try {
            $tokenHash = hash('sha256', $token);
            
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare("INSERT INTO token_blacklist (token_hash, expires_at) VALUES (?, FROM_UNIXTIME(?))");
            $stmt->execute([$tokenHash, $expiresAt]);
        } catch (PDOException $e) {
            // Silently fail - token will expire naturally
        }
    }
    
    /**
     * Base64 URL encode
     */
    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    /**
     * Base64 URL decode
     */
    private static function base64UrlDecode(string $data): string {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $data .= str_repeat('=', 4 - $remainder);
        }
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
