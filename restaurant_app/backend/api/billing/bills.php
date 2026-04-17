<?php
/**
 * GET /api/billing/bills
 * GET /api/billing/bills/{id}
 * POST /api/billing/bills
 * DELETE /api/billing/bills/{id}
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            if (isset($GLOBALS['routeParams']['id'])) {
                // Get single bill
                $id = (int)$GLOBALS['routeParams']['id'];
                $stmt = $db->prepare("SELECT * FROM bills WHERE id = ?");
                $stmt->execute([$id]);
                $bill = $stmt->fetch();
                
                if (!$bill) Response::notFound('Bill not found');
                
                $bill['items_json'] = json_decode($bill['items_json'], true);
                $bill['subtotal'] = (float)$bill['subtotal'];
                $bill['discount_value'] = (float)$bill['discount_value'];
                $bill['total'] = (float)$bill['total'];
                
                Response::success($bill);
            } else {
                // Get all bills with filters
                $dateFilter = $_GET['date'] ?? null;
                $fromDate = $_GET['from'] ?? null;
                $toDate = $_GET['to'] ?? null;
                
                $where = [];
                $params = [];
                
                if ($dateFilter) {
                    $where[] = 'DATE(created_at) = ?';
                    $params[] = $dateFilter;
                }
                if ($fromDate && $toDate) {
                    $where[] = 'DATE(created_at) BETWEEN ? AND ?';
                    $params[] = $fromDate;
                    $params[] = $toDate;
                }
                
                $sql = "SELECT id, bill_number, customer_name, customer_phone, subtotal, discount_type, discount_value, total, payment_status, created_at FROM bills";
                if (!empty($where)) {
                    $sql .= ' WHERE ' . implode(' AND ', $where);
                }
                $sql .= ' ORDER BY created_at DESC';
                
                $stmt = $db->prepare($sql);
                $stmt->execute($params);
                $bills = $stmt->fetchAll();
                
                foreach ($bills as &$bill) {
                    $bill['subtotal'] = (float)$bill['subtotal'];
                    $bill['discount_value'] = (float)$bill['discount_value'];
                    $bill['total'] = (float)$bill['total'];
                }
                
                Response::success($bills);
            }
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) Response::validationError(['body' => 'Invalid JSON body']);
            
            $customerName = trim($input['customer_name'] ?? '');
            $customerPhone = trim($input['customer_phone'] ?? '');
            $items = $input['items'] ?? null;
            $subtotal = isset($input['subtotal']) ? (float)$input['subtotal'] : null;
            $discountType = $input['discount_type'] ?? null;
            $discountValue = isset($input['discount_value']) ? (float)$input['discount_value'] : 0;
            $total = isset($input['total']) ? (float)$input['total'] : null;
            $templateId = isset($input['template_id']) ? (int)$input['template_id'] : null;
            
            $errors = [];
            if (empty($items) || !is_array($items)) $errors['items'] = 'Items array is required';
            if ($subtotal === null) $errors['subtotal'] = 'Subtotal is required';
            if ($total === null) $errors['total'] = 'Total is required';
            
            if (!empty($errors)) Response::validationError($errors);
            if ($discountType && !in_array($discountType, ['percent', 'fixed'])) {
                Response::validationError(['discount_type' => 'Must be "percent" or "fixed"']);
            }
            
            // Generate unique bill number
            $billNumber = 'BILL-' . date('Ymd') . '-' . str_pad(mt_rand(1, 9999), 4, '0', STR_PAD_LEFT);
            
            $stmt = $db->prepare("INSERT INTO bills (bill_number, customer_name, customer_phone, items_json, subtotal, discount_type, discount_value, total, template_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $billNumber, $customerName, $customerPhone, 
                json_encode($items), $subtotal, $discountType, $discountValue, $total, $templateId
            ]);
            
            $newId = $db->lastInsertId();
            $stmt = $db->prepare("SELECT * FROM bills WHERE id = ?");
            $stmt->execute([$newId]);
            $bill = $stmt->fetch();
            $bill['items_json'] = json_decode($bill['items_json'], true);
            
            Response::success($bill, 'Bill created successfully', 201);
            break;
            
        case 'DELETE':
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            if ($id <= 0) Response::notFound('Invalid bill ID');
            
            $stmt = $db->prepare("DELETE FROM bills WHERE id = ?");
            $stmt->execute([$id]);
            
            if ($stmt->rowCount() === 0) Response::notFound('Bill not found');
            
            Response::success(null, 'Bill deleted successfully');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
