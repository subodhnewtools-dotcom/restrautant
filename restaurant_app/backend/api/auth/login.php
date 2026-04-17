<?php
/**
 * POST /api/auth/login
 * Authenticate admin and return JWT token
 */

// Get input data
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    Response::validationError(['body' => 'Invalid JSON body']);
}

$username = trim($input['username'] ?? '');
$password = $input['password'] ?? '';

// Validate inputs
$errors = [];

if (empty($username)) {
    $errors['username'] = 'Username is required';
}

if (empty($password)) {
    $errors['password'] = 'Password is required';
}

if (!empty($errors)) {
    Response::validationError($errors);
}

try {
    $db = Database::getInstance()->getConnection();
    
    // Find admin by username
    $stmt = $db->prepare("SELECT id, username, password, full_name, email, phone, avatar_url FROM admins WHERE username = ?");
    $stmt->execute([$username]);
    $admin = $stmt->fetch();
    
    if (!$admin) {
        Response::unauthorized('Invalid username or password');
    }
    
    // Verify password (SHA256 hash)
    $passwordHash = hash('sha256', $password);
    
    if ($passwordHash !== $admin['password']) {
        Response::unauthorized('Invalid username or password');
    }
    
    // Generate JWT token
    $token = Auth::generateToken($admin['id']);
    
    // Return success with token and admin profile (excluding password)
    Response::success([
        'token' => $token,
        'admin' => [
            'id' => $admin['id'],
            'username' => $admin['username'],
            'full_name' => $admin['full_name'],
            'email' => $admin['email'],
            'phone' => $admin['phone'],
            'avatar_url' => $admin['avatar_url']
        ]
    ], 'Login successful');
    
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
