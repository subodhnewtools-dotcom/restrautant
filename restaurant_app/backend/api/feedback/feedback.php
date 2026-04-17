<?php
/**
 * GET /api/feedback
 * POST /api/feedback
 * DELETE /api/feedback/{id}
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            $stmt = $db->query("SELECT id, stars, comment, customer_name, customer_phone, created_at FROM feedback ORDER BY created_at DESC");
            $feedbacks = $stmt->fetchAll();
            
            // Calculate average rating
            $avgStmt = $db->query("SELECT AVG(stars) as avg_rating, COUNT(*) as count FROM feedback");
            $avg = $avgStmt->fetch();
            
            Response::success([
                'feedbacks' => $feedbacks,
                'average_rating' => $avg['avg_rating'] ? round((float)$avg['avg_rating'], 2) : 0,
                'total_count' => (int)$avg['count']
            ]);
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) Response::validationError(['body' => 'Invalid JSON body']);
            
            $stars = isset($input['stars']) ? (int)$input['stars'] : null;
            $comment = trim($input['comment'] ?? '');
            $customerName = trim($input['customer_name'] ?? '');
            $customerPhone = trim($input['customer_phone'] ?? '');
            
            $errors = [];
            if ($stars === null || $stars < 1 || $stars > 5) {
                $errors['stars'] = 'Rating must be between 1 and 5';
            }
            if (!empty($comment) && strlen($comment) > 200) {
                $errors['comment'] = 'Comment must be 200 characters or less';
            }
            if (!empty($errors)) Response::validationError($errors);
            
            $ipAddress = $_SERVER['REMOTE_ADDR'] ?? null;
            
            $stmt = $db->prepare("INSERT INTO feedback (stars, comment, customer_name, customer_phone, ip_address) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$stars, !empty($comment) ? $comment : null, !empty($customerName) ? $customerName : null, !empty($customerPhone) ? $customerPhone : null, $ipAddress]);
            
            Response::success(['id' => $db->lastInsertId()], 'Feedback submitted successfully', 201);
            break;
            
        case 'DELETE':
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            if ($id <= 0) Response::notFound('Invalid feedback ID');
            
            $stmt = $db->prepare("DELETE FROM feedback WHERE id = ?");
            $stmt->execute([$id]);
            
            if ($stmt->rowCount() === 0) Response::notFound('Feedback not found');
            
            Response::success(null, 'Feedback deleted successfully');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
