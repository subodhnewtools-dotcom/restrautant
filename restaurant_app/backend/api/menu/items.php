<?php
/**
 * GET /api/menu/items?category_id=X
 * POST /api/menu/items
 * PUT /api/menu/items/{id}
 * DELETE /api/menu/items/{id}
 * PATCH /api/menu/items/{id}/stock
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            // Get all items or filter by category (public endpoint)
            $categoryId = isset($_GET['category_id']) ? (int)$_GET['category_id'] : null;
            
            if ($categoryId !== null) {
                $stmt = $db->prepare("
                    SELECT id, category_id, name, description, price, image_url, 
                           is_veg, is_low_stock, is_available, sort_order
                    FROM menu_items 
                    WHERE category_id = ? AND is_available = 1
                    ORDER BY sort_order ASC
                ");
                $stmt->execute([$categoryId]);
            } else {
                $stmt = $db->query("
                    SELECT id, category_id, name, description, price, image_url, 
                           is_veg, is_low_stock, is_available, sort_order
                    FROM menu_items 
                    WHERE is_available = 1
                    ORDER BY sort_order ASC
                ");
            }
            
            $items = $stmt->fetchAll();
            
            // Convert image URLs to absolute
            foreach ($items as &$item) {
                if ($item['image_url']) {
                    $item['image_url'] = BASE_URL . $item['image_url'];
                }
                $item['price'] = (float)$item['price'];
            }
            
            Response::success($items);
            break;
            
        case 'POST':
            // Create new menu item with image upload
            $name = trim($_POST['name'] ?? '');
            $categoryId = isset($_POST['category_id']) ? (int)$_POST['category_id'] : null;
            $description = trim($_POST['description'] ?? '');
            $price = isset($_POST['price']) ? (float)$_POST['price'] : null;
            $isVeg = isset($_POST['is_veg']) ? (int)$_POST['is_veg'] : 1;
            $sortOrder = isset($_POST['sort_order']) ? (int)$_POST['sort_order'] : 0;
            
            // Validate
            $errors = [];
            if (empty($name)) {
                $errors['name'] = 'Item name is required';
            }
            if ($categoryId === null) {
                $errors['category_id'] = 'Category is required';
            }
            if ($price === null) {
                $errors['price'] = 'Price is required';
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }
            
            // Handle image upload
            $imageUrl = null;
            if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
                $uploadResult = FileUpload::handle('image', 'food');
                if (!$uploadResult['success']) {
                    Response::validationError(['image' => $uploadResult['error']]);
                }
                $imageUrl = $uploadResult['relative_url'];
            }
            
            $stmt = $db->prepare("
                INSERT INTO menu_items (category_id, name, description, price, image_url, is_veg, sort_order)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$categoryId, $name, $description, $price, $imageUrl, $isVeg, $sortOrder]);
            
            $newId = $db->lastInsertId();
            
            // Fetch created item
            $stmt = $db->prepare("
                SELECT id, category_id, name, description, price, image_url, 
                       is_veg, is_low_stock, is_available, sort_order
                FROM menu_items WHERE id = ?
            ");
            $stmt->execute([$newId]);
            $item = $stmt->fetch();
            
            if ($item['image_url']) {
                $item['image_url'] = BASE_URL . $item['image_url'];
            }
            $item['price'] = (float)$item['price'];
            
            Response::success($item, 'Menu item created successfully', 201);
            break;
            
        case 'PUT':
            // Update menu item
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            
            if ($id <= 0) {
                Response::notFound('Invalid item ID');
            }
            
            // Get existing item
            $stmt = $db->prepare("SELECT * FROM menu_items WHERE id = ?");
            $stmt->execute([$id]);
            $existingItem = $stmt->fetch();
            
            if (!$existingItem) {
                Response::notFound('Menu item not found');
            }
            
            $name = isset($_POST['name']) ? trim($_POST['name']) : $existingItem['name'];
            $categoryId = isset($_POST['category_id']) ? (int)$_POST['category_id'] : null;
            $description = isset($_POST['description']) ? trim($_POST['description']) : $existingItem['description'];
            $price = isset($_POST['price']) ? (float)$_POST['price'] : (float)$existingItem['price'];
            $isVeg = isset($_POST['is_veg']) ? (int)$_POST['is_veg'] : (int)$existingItem['is_veg'];
            $isAvailable = isset($_POST['is_available']) ? (int)$_POST['is_available'] : (int)$existingItem['is_available'];
            $sortOrder = isset($_POST['sort_order']) ? (int)$_POST['sort_order'] : (int)$existingItem['sort_order'];
            
            // Validate
            $errors = [];
            if (empty($name)) {
                $errors['name'] = 'Item name is required';
            }
            
            if (!empty($errors)) {
                Response::validationError($errors);
            }
            
            // Handle image upload (replace old image if new one uploaded)
            $imageUrl = $existingItem['image_url'];
            if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
                // Delete old image
                if ($imageUrl) {
                    FileUpload::delete($imageUrl);
                }
                
                $uploadResult = FileUpload::handle('image', 'food');
                if (!$uploadResult['success']) {
                    Response::validationError(['image' => $uploadResult['error']]);
                }
                $imageUrl = $uploadResult['relative_url'];
            }
            
            $stmt = $db->prepare("
                UPDATE menu_items 
                SET name = ?, category_id = COALESCE(?, category_id), description = ?, 
                    price = ?, image_url = ?, is_veg = ?, is_available = ?, sort_order = ?,
                    updated_at = NOW()
                WHERE id = ?
            ");
            $stmt->execute([
                $name, $categoryId, $description, $price, $imageUrl, 
                $isVeg, $isAvailable, $sortOrder, $id
            ]);
            
            // Fetch updated item
            $stmt = $db->prepare("
                SELECT id, category_id, name, description, price, image_url, 
                       is_veg, is_low_stock, is_available, sort_order
                FROM menu_items WHERE id = ?
            ");
            $stmt->execute([$id]);
            $item = $stmt->fetch();
            
            if ($item['image_url']) {
                $item['image_url'] = BASE_URL . $item['image_url'];
            }
            $item['price'] = (float)$item['price'];
            
            Response::success($item, 'Menu item updated successfully');
            break;
            
        case 'DELETE':
            // Delete menu item
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            
            if ($id <= 0) {
                Response::notFound('Invalid item ID');
            }
            
            // Get item to delete image
            $stmt = $db->prepare("SELECT image_url FROM menu_items WHERE id = ?");
            $stmt->execute([$id]);
            $item = $stmt->fetch();
            
            if (!$item) {
                Response::notFound('Menu item not found');
            }
            
            // Delete image file
            if ($item['image_url']) {
                FileUpload::delete($item['image_url']);
            }
            
            $stmt = $db->prepare("DELETE FROM menu_items WHERE id = ?");
            $stmt->execute([$id]);
            
            Response::success(null, 'Menu item deleted successfully');
            break;
            
        case 'PATCH':
            // Update stock status
            if (!isset($GLOBALS['routeParams']['action']) || $GLOBALS['routeParams']['action'] !== 'stock') {
                Response::notFound('Invalid endpoint');
            }
            
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            
            if ($id <= 0) {
                Response::notFound('Invalid item ID');
            }
            
            $input = json_decode(file_get_contents('php://input'), true);
            $isLowStock = isset($input['is_low_stock']) ? (int)$input['is_low_stock'] : null;
            
            if ($isLowStock === null) {
                Response::validationError(['is_low_stock' => 'This field is required']);
            }
            
            $stmt = $db->prepare("UPDATE menu_items SET is_low_stock = ?, updated_at = NOW() WHERE id = ?");
            $stmt->execute([$isLowStock, $id]);
            
            if ($stmt->rowCount() === 0) {
                Response::notFound('Menu item not found');
            }
            
            // If low stock, trigger notification (could be enhanced to send FCM)
            if ($isLowStock) {
                // Log notification opportunity - could integrate with FCM here
                error_log("Low stock alert for item ID: $id");
            }
            
            Response::success(['is_low_stock' => $isLowStock], 'Stock status updated');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
    
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
