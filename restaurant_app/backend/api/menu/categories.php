<?php
/**
 * GET /api/menu/categories
 * POST /api/menu/categories
 * PUT /api/menu/categories/{id}
 * DELETE /api/menu/categories/{id}
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            // Get all categories (public endpoint)
            $stmt = $db->query("SELECT id, name, type, sort_order, is_active FROM menu_categories ORDER BY sort_order ASC");
            $categories = $stmt->fetchAll();
            Response::success($categories);
            break;
            
        case 'POST':
            // Create new category
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                Response::validationError(['body' => 'Invalid JSON body']);
            }
            
            $name = trim($input['name'] ?? '');
            $type = $input['type'] ?? 'veg';
            $sortOrder = (int)($input['sort_order'] ?? 0);
            
            // Validate
            $errors = [];
            if (empty($name)) {
                $errors['name'] = 'Category name is required';
            }
            if (!in_array($type, ['veg', 'non_veg'])) {
                $errors['type'] = 'Type must be "veg" or "non_veg"';
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }
            
            $stmt = $db->prepare("INSERT INTO menu_categories (name, type, sort_order) VALUES (?, ?, ?)");
            $stmt->execute([$name, $type, $sortOrder]);
            
            $newId = $db->lastInsertId();
            
            // Fetch created category
            $stmt = $db->prepare("SELECT id, name, type, sort_order, is_active FROM menu_categories WHERE id = ?");
            $stmt->execute([$newId]);
            $category = $stmt->fetch();
            
            Response::success($category, 'Category created successfully', 201);
            break;
            
        case 'PUT':
            // Update category
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            
            if ($id <= 0) {
                Response::notFound('Invalid category ID');
            }
            
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                Response::validationError(['body' => 'Invalid JSON body']);
            }
            
            $name = trim($input['name'] ?? '');
            $type = $input['type'] ?? null;
            $sortOrder = isset($input['sort_order']) ? (int)$input['sort_order'] : null;
            $isActive = isset($input['is_active']) ? (int)$input['is_active'] : null;
            
            // Validate
            $errors = [];
            if (empty($name)) {
                $errors['name'] = 'Category name is required';
            }
            if ($type !== null && !in_array($type, ['veg', 'non_veg'])) {
                $errors['type'] = 'Type must be "veg" or "non_veg"';
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }
            
            // Build update query dynamically
            $updates = [];
            $params = [];
            
            $updates[] = 'name = ?';
            $params[] = $name;
            
            if ($type !== null) {
                $updates[] = 'type = ?';
                $params[] = $type;
            }
            if ($sortOrder !== null) {
                $updates[] = 'sort_order = ?';
                $params[] = $sortOrder;
            }
            if ($isActive !== null) {
                $updates[] = 'is_active = ?';
                $params[] = $isActive;
            }
            
            $updates[] = 'updated_at = NOW()';
            $params[] = $id;
            
            $sql = "UPDATE menu_categories SET " . implode(', ', $updates) . " WHERE id = ?";
            $stmt = $db->prepare($sql);
            $stmt->execute($params);
            
            if ($stmt->rowCount() === 0) {
                Response::notFound('Category not found');
            }
            
            // Fetch updated category
            $stmt = $db->prepare("SELECT id, name, type, sort_order, is_active FROM menu_categories WHERE id = ?");
            $stmt->execute([$id]);
            $category = $stmt->fetch();
            
            Response::success($category, 'Category updated successfully');
            break;
            
        case 'DELETE':
            // Delete category (cascades to items)
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            
            if ($id <= 0) {
                Response::notFound('Invalid category ID');
            }
            
            $stmt = $db->prepare("DELETE FROM menu_categories WHERE id = ?");
            $stmt->execute([$id]);
            
            if ($stmt->rowCount() === 0) {
                Response::notFound('Category not found');
            }
            
            Response::success(null, 'Category deleted successfully');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
    
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
