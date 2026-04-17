<?php
/**
 * GET /api/cms
 * GET /api/cms/{section_key}
 * PUT /api/cms/{section_key}
 */

$requestMethod = $_SERVER['REQUEST_METHOD'];
$db = Database::getInstance()->getConnection();

try {
    switch ($requestMethod) {
        case 'GET':
            if (isset($GLOBALS['routeParams']['id'])) {
                // Get single section
                $sectionKey = $GLOBALS['routeParams']['id'];
                $stmt = $db->prepare("SELECT section_key, content_json, is_published FROM cms_sections WHERE section_key = ?");
                $stmt->execute([$sectionKey]);
                $section = $stmt->fetch();
                
                if (!$section) Response::notFound('Section not found');
                
                $section['content_json'] = json_decode($section['content_json'], true);
                Response::success($section);
            } else {
                // Get all sections
                $stmt = $db->query("SELECT section_key, content_json, is_published FROM cms_sections");
                $sections = $stmt->fetchAll();
                
                $result = [];
                foreach ($sections as $section) {
                    $result[$section['section_key']] = [
                        'content' => json_decode($section['content_json'], true),
                        'is_published' => (bool)$section['is_published']
                    ];
                }
                
                Response::success($result);
            }
            break;
            
        case 'PUT':
            $sectionKey = $GLOBALS['routeParams']['id'] ?? null;
            if (!$sectionKey) Response::notFound('Invalid section key');
            
            // Check if section exists
            $stmt = $db->prepare("SELECT id FROM cms_sections WHERE section_key = ?");
            $stmt->execute([$sectionKey]);
            if (!$stmt->fetch()) Response::notFound('Section not found');
            
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input && empty($_FILES)) {
                Response::validationError(['body' => 'Invalid JSON body or multipart data']);
            }
            
            // Merge JSON input with POST data
            $data = array_merge($input ?? [], $_POST ?? []);
            
            // Handle file uploads for image fields
            $imageFields = ['image', 'images', 'logo', 'favicon'];
            foreach ($imageFields as $field) {
                if (isset($_FILES[$field]) && $_FILES[$field]['error'] === UPLOAD_ERR_OK) {
                    $uploadResult = FileUpload::handle($field, 'banners');
                    if ($uploadResult['success']) {
                        $data[$field] = $uploadResult['relative_url'];
                    }
                }
            }
            
            // Handle multiple image uploads
            if (isset($_FILES['images']) && is_array($_FILES['images']['name'])) {
                $uploadedImages = [];
                for ($i = 0; $i < count($_FILES['images']['name']); $i++) {
                    if ($_FILES['images']['error'][$i] === UPLOAD_ERR_OK) {
                        $tmpName = $_FILES['images']['tmp_name'][$i];
                        $file = [
                            'name' => $_FILES['images']['name'][$i],
                            'type' => $_FILES['images']['type'][$i],
                            'size' => $_FILES['images']['size'][$i],
                            'tmp_name' => $tmpName,
                            'error' => $_FILES['images']['error'][$i]
                        ];
                        
                        $_FILES['image_single'] = $file;
                        $uploadResult = FileUpload::handle('image_single', 'gallery');
                        if ($uploadResult['success']) {
                            $uploadedImages[] = $uploadResult['relative_url'];
                        }
                    }
                }
                if (!empty($uploadedImages)) {
                    $data['images'] = $uploadedImages;
                }
            }
            
            // Get existing content and merge updates
            $stmt = $db->prepare("SELECT content_json FROM cms_sections WHERE section_key = ?");
            $stmt->execute([$sectionKey]);
            $existing = json_decode($stmt->fetch()['content_json'], true);
            
            $updatedContent = array_merge($existing, $data);
            
            $stmt = $db->prepare("UPDATE cms_sections SET content_json = ?, draft_json = ?, is_published = 0, updated_at = NOW() WHERE section_key = ?");
            $stmt->execute([json_encode($updatedContent), json_encode($updatedContent), $sectionKey]);
            
            Response::success(['section_key' => $sectionKey, 'content' => $updatedContent], 'Section updated successfully (draft)');
            break;
            
        default:
            Response::error('Method not allowed', 405);
    }
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
