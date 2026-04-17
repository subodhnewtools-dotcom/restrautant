<?php
/**
 * POST /api/auth/change-password
 * Change admin password
 */

$adminId = Auth::requireAuth();

// Get input data
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    Response::validationError(['body' => 'Invalid JSON body']);
}

$currentPassword = $input['current_password'] ?? '';
$newPassword = $input['new_password'] ?? '';

// Validate inputs
$errors = [];

if (empty($currentPassword)) {
    $errors['current_password'] = 'Current password is required';
}

if (empty($newPassword)) {
    $errors['new_password'] = 'New password is required';
} elseif (strlen($newPassword) < 6) {
    $errors['new_password'] = 'New password must be at least 6 characters';
}

if (!empty($errors)) {
    Response::validationError($errors);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Get current admin record
    $stmt = $db->prepare("SELECT password FROM admins WHERE id = ?");
    $stmt->execute([$adminId]);
    $admin = $stmt->fetch();
    
    if (!$admin) {
        Response::notFound('Admin not found');
    }
    
    // Verify current password
    $currentHash = hash('sha256', $currentPassword);
    
    if ($currentHash !== $admin['password']) {
        Response::error('Current password is incorrect', 403);
    }
    
    // Hash new password
    $newHash = hash('sha256', $newPassword);
    
    // Update password
    $stmt = $db->prepare("UPDATE admins SET password = ?, updated_at = NOW() WHERE id = ?");
    $stmt->execute([$newHash, $adminId]);
    
    Response::success(null, 'Password changed successfully');
    
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
