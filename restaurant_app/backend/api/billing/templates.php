<?php
/**
 * GET /api/billing/templates
 * POST /api/billing/templates
 * PUT /api/billing/templates/{id}
 * DELETE /api/billing/templates/{id}
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            $stmt = $db->query("SELECT id, name, brand_name, footer_text, logo_url, font_style, primary_color, is_default FROM bill_templates ORDER BY is_default DESC, name ASC");
            $templates = $stmt->fetchAll();
            
            foreach ($templates as &$template) {
                if ($template['logo_url']) {
                    $template['logo_url'] = BASE_URL . $template['logo_url'];
                }
            }
            
            Response::success($templates);
            break;
            
        case 'POST':
            $name = trim($_POST['name'] ?? '');
            $brandName = trim($_POST['brand_name'] ?? '');
            $footerText = trim($_POST['footer_text'] ?? '');
            $fontStyle = trim($_POST['font_style'] ?? 'Arial');
            $primaryColor = trim($_POST['primary_color'] ?? '#E8630A');
            $isDefault = isset($_POST['is_default']) ? (int)$_POST['is_default'] : 0;
            
            $errors = [];
            if (empty($name)) $errors['name'] = 'Template name is required';
            if (empty($brandName)) $errors['brand_name'] = 'Brand name is required';
            
            if (!empty($errors)) Response::validationError($errors);
            
            // If setting as default, unset other defaults
            if ($isDefault) {
                $db->prepare("UPDATE bill_templates SET is_default = 0")->execute();
            }
            
            $logoUrl = null;
            if (isset($_FILES['logo']) && $_FILES['logo']['error'] === UPLOAD_ERR_OK) {
                $uploadResult = FileUpload::handle('logo', 'logos');
                if (!$uploadResult['success']) Response::validationError(['logo' => $uploadResult['error']]);
                $logoUrl = $uploadResult['relative_url'];
            }
            
            $stmt = $db->prepare("INSERT INTO bill_templates (name, brand_name, footer_text, logo_url, font_style, primary_color, is_default) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$name, $brandName, $footerText, $logoUrl, $fontStyle, $primaryColor, $isDefault]);
            
            $newId = $db->lastInsertId();
            $stmt = $db->prepare("SELECT id, name, brand_name, footer_text, logo_url, font_style, primary_color, is_default FROM bill_templates WHERE id = ?");
            $stmt->execute([$newId]);
            $template = $stmt->fetch();
            
            if ($template['logo_url']) $template['logo_url'] = BASE_URL . $template['logo_url'];
            
            Response::success($template, 'Template created successfully', 201);
            break;
            
        case 'PUT':
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            if ($id <= 0) Response::notFound('Invalid template ID');
            
            $stmt = $db->prepare("SELECT * FROM bill_templates WHERE id = ?");
            $stmt->execute([$id]);
            $existing = $stmt->fetch();
            if (!$existing) Response::notFound('Template not found');
            
            $name = isset($_POST['name']) ? trim($_POST['name']) : $existing['name'];
            $brandName = isset($_POST['brand_name']) ? trim($_POST['brand_name']) : $existing['brand_name'];
            $footerText = isset($_POST['footer_text']) ? trim($_POST['footer_text']) : $existing['footer_text'];
            $fontStyle = isset($_POST['font_style']) ? trim($_POST['font_style']) : $existing['font_style'];
            $primaryColor = isset($_POST['primary_color']) ? trim($_POST['primary_color']) : $existing['primary_color'];
            $isDefault = isset($_POST['is_default']) ? (int)$_POST['is_default'] : (int)$existing['is_default'];
            
            $errors = [];
            if (empty($name)) $errors['name'] = 'Template name is required';
            if (empty($brandName)) $errors['brand_name'] = 'Brand name is required';
            if (!empty($errors)) Response::validationError($errors);
            
            if ($isDefault) {
                $db->prepare("UPDATE bill_templates SET is_default = 0 WHERE id != ?")->execute([$id]);
            }
            
            $logoUrl = $existing['logo_url'];
            if (isset($_FILES['logo']) && $_FILES['logo']['error'] === UPLOAD_ERR_OK) {
                if ($logoUrl) FileUpload::delete($logoUrl);
                $uploadResult = FileUpload::handle('logo', 'logos');
                if (!$uploadResult['success']) Response::validationError(['logo' => $uploadResult['error']]);
                $logoUrl = $uploadResult['relative_url'];
            }
            
            $stmt = $db->prepare("UPDATE bill_templates SET name=?, brand_name=?, footer_text=?, logo_url=?, font_style=?, primary_color=?, is_default=?, updated_at=NOW() WHERE id=?");
            $stmt->execute([$name, $brandName, $footerText, $logoUrl, $fontStyle, $primaryColor, $isDefault, $id]);
            
            $stmt = $db->prepare("SELECT id, name, brand_name, footer_text, logo_url, font_style, primary_color, is_default FROM bill_templates WHERE id = ?");
            $stmt->execute([$id]);
            $template = $stmt->fetch();
            if ($template['logo_url']) $template['logo_url'] = BASE_URL . $template['logo_url'];
            
            Response::success($template, 'Template updated successfully');
            break;
            
        case 'DELETE':
            $id = (int)($GLOBALS['routeParams']['id'] ?? 0);
            if ($id <= 0) Response::notFound('Invalid template ID');
            
            $stmt = $db->prepare("SELECT logo_url FROM bill_templates WHERE id = ?");
            $stmt->execute([$id]);
            $template = $stmt->fetch();
            
            if (!$template) Response::notFound('Template not found');
            if ($template['logo_url']) FileUpload::delete($template['logo_url']);
            
            $stmt = $db->prepare("DELETE FROM bill_templates WHERE id = ?");
            $stmt->execute([$id]);
            
            Response::success(null, 'Template deleted successfully');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
