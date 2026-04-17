-- ============================================
-- Restaurant App Database Schema
-- MySQL 8.0+ Compatible
-- ============================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- ============================================
-- TABLE: admins
-- Store admin user credentials and profile
-- ============================================
CREATE TABLE IF NOT EXISTS `admins` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` CHAR(64) NOT NULL COMMENT 'SHA256 hash',
    `full_name` VARCHAR(100) DEFAULT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    `phone` VARCHAR(20) DEFAULT NULL,
    `avatar_url` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default admin (username: admin, password: admin123)
INSERT INTO `admins` (`username`, `password`, `full_name`) VALUES
('admin', SHA2('admin123', 256), 'Restaurant Admin');

-- ============================================
-- TABLE: token_blacklist
-- Store revoked JWT tokens until expiry
-- ============================================
CREATE TABLE IF NOT EXISTS `token_blacklist` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `token_hash` CHAR(64) NOT NULL UNIQUE COMMENT 'SHA256 of token',
    `expires_at` TIMESTAMP NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: menu_categories
-- Food categories (Veg/Non-Veg)
-- ============================================
CREATE TABLE IF NOT EXISTS `menu_categories` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `type` ENUM('veg', 'non_veg') NOT NULL DEFAULT 'veg',
    `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_sort_order` (`sort_order`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: menu_items
-- Individual food items with images
-- ============================================
CREATE TABLE IF NOT EXISTS `menu_items` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `price` DECIMAL(10,2) NOT NULL,
    `image_url` VARCHAR(255) DEFAULT NULL,
    `is_veg` TINYINT(1) NOT NULL DEFAULT 1,
    `is_low_stock` TINYINT(1) NOT NULL DEFAULT 0,
    `is_available` TINYINT(1) NOT NULL DEFAULT 1,
    `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_category_id` (`category_id`),
    INDEX `idx_is_available` (`is_available`),
    INDEX `idx_sort_order` (`sort_order`),
    CONSTRAINT `fk_menu_items_category` 
        FOREIGN KEY (`category_id`) REFERENCES `menu_categories`(`id`) 
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: bill_templates
-- Customizable bill/invoice templates
-- ============================================
CREATE TABLE IF NOT EXISTS `bill_templates` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `brand_name` VARCHAR(150) NOT NULL,
    `footer_text` TEXT DEFAULT NULL,
    `logo_url` VARCHAR(255) DEFAULT NULL,
    `font_style` VARCHAR(50) DEFAULT 'Arial',
    `primary_color` VARCHAR(7) DEFAULT '#E8630A',
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_is_default` (`is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default template
INSERT INTO `bill_templates` (`name`, `brand_name`, `footer_text`, `is_default`) VALUES
('Default Template', 'My Restaurant', 'Thank you for dining with us!', 1);

-- ============================================
-- TABLE: bills
-- Saved bill records
-- ============================================
CREATE TABLE IF NOT EXISTS `bills` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bill_number` VARCHAR(50) NOT NULL UNIQUE,
    `customer_name` VARCHAR(100) DEFAULT NULL,
    `customer_phone` VARCHAR(20) DEFAULT NULL,
    `items_json` JSON NOT NULL COMMENT 'Array of {item_id, name, qty, price, subtotal}',
    `subtotal` DECIMAL(10,2) NOT NULL,
    `discount_type` ENUM('percent', 'fixed') DEFAULT NULL,
    `discount_value` DECIMAL(10,2) DEFAULT 0,
    `total` DECIMAL(10,2) NOT NULL,
    `template_id` INT UNSIGNED DEFAULT NULL,
    `payment_status` ENUM('pending', 'paid', 'refunded') NOT NULL DEFAULT 'pending',
    `server_id` INT UNSIGNED DEFAULT NULL COMMENT 'Sync tracking',
    `synced` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_bill_number` (`bill_number`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_synced` (`synced`),
    INDEX `idx_server_id` (`server_id`),
    CONSTRAINT `fk_bills_template` 
        FOREIGN KEY (`template_id`) REFERENCES `bill_templates`(`id`) 
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: message_templates
-- Quick message templates for customer communication
-- ============================================
CREATE TABLE IF NOT EXISTS `message_templates` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(100) NOT NULL,
    `body` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample message templates
INSERT INTO `message_templates` (`title`, `body`) VALUES
('Order Confirmation', 'Hi {customer_name}, your order #{bill_number} of ₹{total_amount} is confirmed!'),
('Thank You', 'Thank you for visiting {restaurant_name}! We hope to see you again soon.'),
('Feedback Request', 'Hi {customer_name}, how was your experience at {restaurant_name}? Rate us: {feedback_link}');

-- ============================================
-- TABLE: cms_sections
-- Content Management System sections for web app
-- ============================================
CREATE TABLE IF NOT EXISTS `cms_sections` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `section_key` VARCHAR(50) NOT NULL UNIQUE,
    `content_json` JSON NOT NULL,
    `is_published` TINYINT(1) NOT NULL DEFAULT 0,
    `draft_json` JSON DEFAULT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_section_key` (`section_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pre-populate CMS sections
INSERT INTO `cms_sections` (`section_key`, `content_json`, `is_published`) VALUES
('hero_banner', '{"slides": [{"image": "", "title": "Welcome", "subtitle": "Experience the best cuisine", "cta_text": "View Menu", "cta_link": "/menu"}], "transition_speed": 5000}', 1),
('offers', '{"offers": []}', 1),
('about_us', '{"title": "About Us", "content": "", "images": []}', 1),
('gallery', '{"images": []}', 1),
('contact', '{"phone": "", "address": "", "email": "", "working_hours": {"monday": {"open": true, "start": "09:00", "end": "22:00"}, "tuesday": {"open": true, "start": "09:00", "end": "22:00"}, "wednesday": {"open": true, "start": "09:00", "end": "22:00"}, "thursday": {"open": true, "start": "09:00", "end": "22:00"}, "friday": {"open": true, "start": "09:00", "end": "23:00"}, "saturday": {"open": true, "start": "09:00", "end": "23:00"}, "sunday": {"open": true, "start": "10:00", "end": "22:00"}}, "maps_url": ""}', 1),
('social_links', '{"instagram": "", "facebook": "", "whatsapp": ""}', 1),
('announcement_bar', '{"enabled": false, "text": "", "speed": 50}', 1),
('menu_settings', '{"categories": [], "hidden_categories": []}', 1),
('footer', '{"address": "", "copyright": "", "tagline": ""}', 1),
('color_theme', '{"accent_color": "#E8630A"}', 1),
('seo', '{"page_title": "Restaurant", "meta_description": "", "favicon_url": ""}', 1),
('today_special', '{"enabled": false, "item_id": null}', 1);

-- ============================================
-- TABLE: feedback
-- Customer feedback and ratings
-- ============================================
CREATE TABLE IF NOT EXISTS `feedback` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `stars` TINYINT UNSIGNED NOT NULL CHECK (`stars` BETWEEN 1 AND 5),
    `comment` VARCHAR(200) DEFAULT NULL,
    `customer_name` VARCHAR(100) DEFAULT NULL,
    `customer_phone` VARCHAR(20) DEFAULT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_stars` (`stars`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: notifications_log
-- Log of all sent notifications
-- ============================================
CREATE TABLE IF NOT EXISTS `notifications_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `topic` VARCHAR(50) NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `body` TEXT NOT NULL,
    `data_json` JSON DEFAULT NULL,
    `sent_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `status` ENUM('sent', 'failed') NOT NULL DEFAULT 'sent',
    `error_message` TEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_topic` (`topic`),
    INDEX `idx_sent_at` (`sent_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: printer_config
-- Saved printer configuration
-- ============================================
CREATE TABLE IF NOT EXISTS `printer_config` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `device_id` VARCHAR(100) NOT NULL UNIQUE,
    `device_name` VARCHAR(150) NOT NULL,
    `device_type` ENUM('bluetooth', 'windows') NOT NULL,
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_is_default` (`is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE: sync_queue
-- Queue for offline operations to sync when online
-- ============================================
CREATE TABLE IF NOT EXISTS `sync_queue` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `operation` ENUM('create', 'update', 'delete') NOT NULL,
    `entity_type` VARCHAR(50) NOT NULL COMMENT 'e.g., bill, menu_item, cms_section',
    `entity_id` INT UNSIGNED DEFAULT NULL,
    `server_id` INT UNSIGNED DEFAULT NULL,
    `payload_json` JSON NOT NULL,
    `retry_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `last_attempt` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_entity_type` (`entity_type`),
    INDEX `idx_retry_count` (`retry_count`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- End of Schema
-- ============================================
