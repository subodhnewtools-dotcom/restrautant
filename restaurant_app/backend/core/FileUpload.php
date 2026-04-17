<?php
/**
 * File Upload Handler
 * Validates, compresses, and manages file uploads
 */

class FileUpload {
    private const ALLOWED_MIME_TYPES = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/gif' => 'gif',
        'image/webp' => 'webp'
    ];
    
    private const MAX_FILE_SIZE = UPLOAD_MAX_SIZE_MB * 1024 * 1024;
    
    /**
     * Handle file upload
     * 
     * @param string $fileKey Name of the file input field
     * @param string $subfolder Subfolder within uploads directory
     * @return array{success: bool, url?: string, error?: string}
     */
    public static function handle(string $fileKey, string $subfolder): array {
        // Check if file was uploaded
        if (!isset($_FILES[$fileKey])) {
            return ['success' => false, 'error' => 'No file uploaded'];
        }
        
        $file = $_FILES[$fileKey];
        
        // Check for upload errors
        if ($file['error'] !== UPLOAD_ERR_OK) {
            return ['success' => false, 'error' => self::getUploadErrorMessage($file['error'])];
        }
        
        // Validate file size
        if ($file['size'] > self::MAX_FILE_SIZE) {
            return ['success' => false, 'error' => 'File size exceeds maximum allowed (' . UPLOAD_MAX_SIZE_MB . 'MB)'];
        }
        
        // Validate MIME type
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->file($file['tmp_name']);
        
        if (!isset(self::ALLOWED_MIME_TYPES[$mimeType])) {
            return ['success' => false, 'error' => 'Invalid file type. Allowed: JPEG, PNG, GIF, WebP'];
        }
        
        // Create subfolder if it doesn't exist
        $uploadDir = UPLOAD_BASE_PATH . $subfolder;
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        // Generate unique filename
        $extension = self::ALLOWED_MIME_TYPES[$mimeType];
        $filename = self::generateUuid() . '.' . $extension;
        $filePath = $uploadDir . '/' . $filename;
        
        // Load and compress image
        $imageResource = self::loadImage($file['tmp_name'], $mimeType);
        if (!$imageResource) {
            return ['success' => false, 'error' => 'Failed to process image'];
        }
        
        // Compress and save (80% quality for JPEG/WebP)
        $compressed = self::saveImage($imageResource, $filePath, $mimeType, 80);
        imagedestroy($imageResource);
        
        if (!$compressed) {
            return ['success' => false, 'error' => 'Failed to save image'];
        }
        
        // Return relative URL
        $relativeUrl = '/uploads/' . $subfolder . '/' . $filename;
        $absoluteUrl = BASE_URL . $relativeUrl;
        
        return ['success' => true, 'url' => $absoluteUrl, 'relative_url' => $relativeUrl];
    }
    
    /**
     * Delete uploaded file
     * 
     * @param string $relativePath Relative path from uploads directory
     * @return bool Success status
     */
    public static function delete(string $relativePath): bool {
        // Remove leading slash if present
        $relativePath = ltrim($relativePath, '/');
        
        // Prevent directory traversal
        if (strpos($relativePath, '..') !== false) {
            return false;
        }
        
        $filePath = UPLOAD_BASE_PATH . $relativePath;
        
        if (file_exists($filePath) && is_file($filePath)) {
            return unlink($filePath);
        }
        
        return false;
    }
    
    /**
     * Get upload error message
     */
    private static function getUploadErrorMessage(int $errorCode): string {
        return match($errorCode) {
            UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE => 'File size exceeds maximum allowed',
            UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'A PHP extension stopped the upload',
            default => 'Unknown upload error'
        };
    }
    
    /**
     * Generate UUID v4
     */
    private static function generateUuid(): string {
        $data = random_bytes(16);
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }
    
    /**
     * Load image resource from file
     */
    private static function loadImage(string $path, string $mimeType): GdImage|false {
        return match($mimeType) {
            'image/jpeg' => imagecreatefromjpeg($path),
            'image/png' => imagecreatefrompng($path),
            'image/gif' => imagecreatefromgif($path),
            'image/webp' => imagecreatefromwebp($path),
            default => false
        };
    }
    
    /**
     * Save image resource to file with compression
     */
    private static function saveImage(GdImage $resource, string $path, string $mimeType, int $quality): bool {
        return match($mimeType) {
            'image/jpeg' => imagejpeg($resource, $path, $quality),
            'image/png' => imagepng($resource, $path, max(0, min(9, (int)(9 - ($quality / 12))))),
            'image/gif' => imagegif($resource, $path),
            'image/webp' => imagewebp($resource, $path, $quality),
            default => false
        };
    }
}
