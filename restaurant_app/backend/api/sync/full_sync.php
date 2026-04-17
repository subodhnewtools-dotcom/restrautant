<?php
/**
 * GET /api/sync/full_sync
 * Full bi-directional sync endpoint
 * Returns all data for offline-first admin app
 */

$adminId = Auth::requireAuth();
$db = Database::getInstance()->getConnection();

try {
    $response = [];
    
    // Get categories
    $stmt = $db->query("SELECT id, name, type, sort_order, is_active FROM menu_categories ORDER BY sort_order ASC");
    $response['categories'] = $stmt->fetchAll();
    
    // Get menu items with absolute URLs
    $stmt = $db->query("SELECT id, category_id, name, description, price, image_url, is_veg, is_low_stock, is_available, sort_order FROM menu_items WHERE is_available = 1 ORDER BY sort_order ASC");
    $items = $stmt->fetchAll();
    foreach ($items as &$item) {
        if ($item['image_url']) {
            $item['image_url'] = BASE_URL . $item['image_url'];
        }
        $item['price'] = (float)$item['price'];
    }
    $response['menu_items'] = $items;
    
    // Get bill templates with absolute URLs
    $stmt = $db->query("SELECT id, name, brand_name, footer_text, logo_url, font_style, primary_color, is_default FROM bill_templates ORDER BY is_default DESC");
    $templates = $stmt->fetchAll();
    foreach ($templates as &$template) {
        if ($template['logo_url']) {
            $template['logo_url'] = BASE_URL . $template['logo_url'];
        }
    }
    $response['bill_templates'] = $templates;
    
    // Get message templates
    $stmt = $db->query("SELECT id, title, body FROM message_templates ORDER BY created_at DESC");
    $response['messages'] = $stmt->fetchAll();
    
    // Get CMS sections
    $stmt = $db->query("SELECT section_key, content_json, is_published FROM cms_sections WHERE is_published = 1");
    $cmsSections = $stmt->fetchAll();
    $cms = [];
    foreach ($cmsSections as $section) {
        $cms[$section['section_key']] = json_decode($section['content_json'], true);
    }
    $response['cms'] = $cms;
    
    // Add sync timestamp
    $response['sync_timestamp'] = time();
    
    Response::success($response, 'Full sync completed');
    
} catch (PDOException $e) {
    Response::serverError('Database error: ' . $e->getMessage());
}
