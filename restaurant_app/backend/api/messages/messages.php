<?php
/**
 * GET /api/messages
 * POST /api/messages
 * PUT /api/messages/{id}
 * DELETE /api/messages/{id}
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            $stmt = $db->query("SELECT id, title, body, created_at, updated_at FROM message_templates ORDER BY created_at DESC");
            Response::success($stmt->fetchAll());
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) Response::validationError(['body' => 'Invalid JSON body']);
            
            $title = trim($input['title'] ?? '');
            $body = trim($input['body'] ?? '');
            
            $errors = [];
            if (empty($title)) $errors['title'] = 'Title is required';
            if (empty($body)) $errors['body'] = 'Body is required';
            if (!empty($errors)) Response::validationError($errors);
            
            $stmt = $db->prepare("INSERT INTO message_templates (title, body) VALUES (?, ?)");
            $stmt->execute([$title, $body]);
            
            $newId = $db->lastInsertId();
            $stmt = $db->prepare("SELECT id, title, body, created_at, updated_at FROM message_templates WHERE id = ?");
            $stmt->execute([$newId]);
            
            Response::success($stmt->fetch(), 'Message template created successfully', 201);
            break;
            
        case 'PUT':
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            if ($id <= 0) Response::notFound('Invalid message ID');
            
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) Response::validationError(['body' => 'Invalid JSON body']);
            
            $title = isset($input['title']) ? trim($input['title']) : null;
            $body = isset($input['body']) ? trim($input['body']) : null;
            
            $errors = [];
            if ($title !== null && empty($title)) $errors['title'] = 'Title cannot be empty';
            if ($body !== null && empty($body)) $errors['body'] = 'Body cannot be empty';
            if (!empty($errors)) Response::validationError($errors);
            
            $updates = [];
            $params = [];
            if ($title !== null) { $updates[] = 'title = ?'; $params[] = $title; }
            if ($body !== null) { $updates[] = 'body = ?'; $params[] = $body; }
            $updates[] = 'updated_at = NOW()';
            $params[] = $id;
            
            $stmt = $db->prepare("UPDATE message_templates SET " . implode(', ', $updates) . " WHERE id = ?");
            $stmt->execute($params);
            
            if ($stmt->rowCount() === 0) Response::notFound('Message template not found');
            
            $stmt = $db->prepare("SELECT id, title, body, created_at, updated_at FROM message_templates WHERE id = ?");
            $stmt->execute([$id]);
            
            Response::success($stmt->fetch(), 'Message template updated successfully');
            break;
            
        case 'DELETE':
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            if ($id <= 0) Response::notFound('Invalid message ID');
            
            $stmt = $db->prepare("DELETE FROM message_templates WHERE id = ?");
            $stmt->execute([$id]);
            
            if ($stmt->rowCount() === 0) Response::notFound('Message template not found');
            
            Response::success(null, 'Message template deleted successfully');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
