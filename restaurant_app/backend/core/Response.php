<?php
/**
 * Standardized JSON Response Helper
 * Ensures consistent API response format
 */

class Response {
    /**
     * Send success response
     * 
     * @param mixed $data Response data (array, object, or null)
     * @param string $message Success message
     * @param int $code HTTP status code
     * @return void
     */
    public static function success(mixed $data = null, string $message = 'Success', int $code = 200): void {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        
        $response = [
            'success' => true,
            'message' => $message,
            'data' => $data
        ];
        
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }
    
    /**
     * Send error response
     * 
     * @param string $message Error message
     * @param int $code HTTP status code
     * @param mixed $errors Additional error details (optional)
     * @return void
     */
    public static function error(string $message, int $code = 400, mixed $errors = null): void {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        
        $response = [
            'success' => false,
            'message' => $message
        ];
        
        if ($errors !== null) {
            $response['errors'] = $errors;
        }
        
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }
    
    /**
     * Send validation error response
     * 
     * @param array $errors Array of field-specific errors
     * @return void
     */
    public static function validationError(array $errors): void {
        self::error('Validation failed', 422, $errors);
    }
    
    /**
     * Send unauthorized response
     * 
     * @param string $message Error message
     * @return void
     */
    public static function unauthorized(string $message = 'Unauthorized'): void {
        self::error($message, 401);
    }
    
    /**
     * Send not found response
     * 
     * @param string $message Error message
     * @return void
     */
    public static function notFound(string $message = 'Resource not found'): void {
        self::error($message, 404);
    }
    
    /**
     * Send server error response
     * 
     * @param string $message Error message
     * @return void
     */
    public static function serverError(string $message = 'Internal server error'): void {
        self::error($message, 500);
    }
}
