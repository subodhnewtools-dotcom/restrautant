# 🚀 Restaurant App - Complete Implementation Plan

> **Master Build Roadmap** - Sequential execution plan for building the entire production-ready restaurant application

---

## 📋 Overview

**Total Estimated Files:** ~180-220 files  
**Total Estimated Lines of Code:** ~35,000-45,000 lines  
**Recommended Build Order:** Backend First → Flutter Core → Features → Web App  

---

## 🎯 Phase 0: Foundation Setup (Day 1)

### 0.1 Initialize Project Structure
- [ ] Create all root folders (`main_app/`, `backend/`, `docs/`)
- [ ] Initialize Flutter project in `main_app/` with Android, Windows, Web platforms
- [ ] Set up Git repository with `.gitignore`
- [ ] Create empty placeholder files for all planned modules

### 0.2 Backend Foundation
**Files to Create: 8**
- [ ] `backend/config/database.php` - PDO singleton connection
- [ ] `backend/config/app_config.php` - Application constants
- [ ] `backend/config/schema.sql` - Complete database schema with seed data
- [ ] `backend/core/Database.php` - Database singleton class
- [ ] `backend/core/Response.php` - Standardized JSON response helper
- [ ] `backend/core/Auth.php` - JWT token generation/verification
- [ ] `backend/core/FileUpload.php` - Image upload, validation, compression
- [ ] `backend/.htaccess` - Apache rewrite rules and CORS
- [ ] `backend/index.php` - API router entry point
- [ ] `backend/uploads/.htaccess` - Block PHP execution in uploads

**Testing Checklist:**
- Manual database import works
- Test connection via simple PHP script
- Verify `.htaccess` routing works

---

## 🎯 Phase 1: Backend API Endpoints (Days 2-3)

### 1.1 Authentication Module
**Files: 3**
- [ ] `backend/api/auth/login.php` - POST login with SHA-256 password
- [ ] `backend/api/auth/logout.php` - POST logout, blacklist token
- [ ] `backend/api/auth/change_password.php` - POST change password

**Test Cases:**
- Login with correct/incorrect credentials
- Token generation and expiration
- Token blacklist functionality
- Password change validation

### 1.2 Menu Management Module
**Files: 2**
- [ ] `backend/api/menu/categories.php` - GET/POST/PUT/DELETE categories
- [ ] `backend/api/menu/items.php` - GET/POST/PUT/DELETE/PATCH items with image upload

**Test Cases:**
- CRUD operations for categories
- Image upload and compression
- Stock status updates trigger FCM
- Cascade delete categories → items

### 1.3 Billing Module
**Files: 2**
- [ ] `backend/api/billing/templates.php` - CRUD bill templates with logo upload
- [ ] `backend/api/billing/bills.php` - CRUD bills with date filtering

**Test Cases:**
- Template creation with logo
- Bill save with items array
- Date range queries
- Bill retrieval with parsed items_json

### 1.4 Messages & CMS Module
**Files: 2**
- [ ] `backend/api/messages/messages.php` - CRUD message templates
- [ ] `backend/api/cms/cms.php` - GET/PUT CMS sections with image handling

**Test Cases:**
- Message template CRUD
- CMS section retrieval (public)
- CMS update with image uploads
- Multi-image hero banner handling

### 1.5 Feedback & Notifications Module
**Files: 2**
- [ ] `backend/api/feedback/feedback.php` - GET feedback, POST new feedback
- [ ] `backend/api/notifications/notify.php` - POST send FCM notification

**Test Cases:**
- Public feedback submission
- Admin feedback retrieval with average rating
- FCM push notification sending
- Notification logging

### 1.6 Sync Endpoint
**Files: 1**
- [ ] `backend/api/sync/full_sync.php` - Full data export for sync

**Test Cases:**
- Returns all categories, items, templates, messages, CMS
- Absolute image URLs
- Sync timestamp included

---

## 🎯 Phase 2: Flutter Core Setup (Days 4-5)

### 2.1 Dependencies & Configuration
**Files: 3**
- [ ] `main_app/pubspec.yaml` - All dependencies + assets configuration
- [ ] `main_app/lib/config/app_config.dart` - Base URL, constants, supported locales
- [ ] `main_app/lib/main.dart` - Entry point with ProviderScope, platform detection

**Verification:**
- `flutter pub get` succeeds
- All platforms build (web, android, windows)
- Firebase configuration files in place

### 2.2 Theme System
**Files: 2**
- [ ] `main_app/lib/shared/theme/app_theme.dart` - Material 3 theme with all colors
- [ ] `main_app/lib/shared/theme/color_palette.dart` - Color constants

**Verification:**
- Theme applies correctly
- All color tokens accessible
- Text themes configured (Poppins, Inter, RobotoMono)

### 2.3 Local Database (Drift)
**Files: 12**
- [ ] `main_app/lib/core/database/app_database.dart` - Main database definition
- [ ] `main_app/lib/core/database/tables/admin_session_table.dart`
- [ ] `main_app/lib/core/database/tables/menu_categories_table.dart`
- [ ] `main_app/lib/core/database/tables/menu_items_table.dart`
- [ ] `main_app/lib/core/database/tables/bill_templates_table.dart`
- [ ] `main_app/lib/core/database/tables/bills_table.dart`
- [ ] `main_app/lib/core/database/tables/message_templates_table.dart`
- [ ] `main_app/lib/core/database/tables/cms_content_table.dart`
- [ ] `main_app/lib/core/database/tables/notifications_log_table.dart`
- [ ] `main_app/lib/core/database/tables/printer_config_table.dart`
- [ ] `main_app/lib/core/database/tables/sync_queue_table.dart`
- [ ] `main_app/lib/core/database/tables/token_blacklist_table.dart`

**DAOs:**
- [ ] `main_app/lib/core/database/daos/admin_dao.dart`
- [ ] `main_app/lib/core/database/daos/menu_dao.dart`
- [ ] `main_app/lib/core/database/daos/billing_dao.dart`
- [ ] `main_app/lib/core/database/daos/messages_dao.dart`
- [ ] `main_app/lib/core/database/daos/cms_dao.dart`
- [ ] `main_app/lib/core/database/daos/notifications_dao.dart`
- [ ] `main_app/lib/core/database/daos/sync_dao.dart`

**Verification:**
- `build_runner` generates code successfully
- All CRUD operations work
- Foreign key constraints enforced

### 2.4 Network Layer
**Files: 4**
- [ ] `main_app/lib/core/network/api_client.dart` - Dio client with interceptors
- [ ] `main_app/lib/core/network/endpoints.dart` - All API endpoint strings
- [ ] `main_app/lib/core/network/interceptors/auth_interceptor.dart`
- [ ] `main_app/lib/core/network/interceptors/error_interceptor.dart`
- [ ] `main_app/lib/core/network/interceptors/connectivity_interceptor.dart`
- [ ] `main_app/lib/core/network/models/api_error.dart`
- [ ] `main_app/lib/core/network/models/offline_exception.dart`

**Verification:**
- Auth header injected correctly
- Error responses parsed properly
- Offline detection works

### 2.5 Sync Engine
**Files: 3**
- [ ] `main_app/lib/core/sync/sync_service.dart` - Bi-directional sync logic
- [ ] `main_app/lib/core/sync/sync_status.dart` - Sync status model
- [ ] `main_app/lib/core/sync/image_downloader.dart` - Download images from server

**Verification:**
- Periodic sync runs every N seconds
- Queue processing works offline→online
- Images downloaded to local storage

### 2.6 Notifications Services
**Files: 3**
- [ ] `main_app/lib/core/notifications/fcm_service.dart` - Firebase Cloud Messaging
- [ ] `main_app/lib/core/notifications/local_notif.dart` - Local notifications
- [ ] `main_app/lib/core/notifications/notification_handler.dart` - Handle incoming notifications

**Verification:**
- FCM subscription works
- Foreground notifications display
- Daily summary scheduled

### 2.7 Shared Utilities
**Files: 6**
- [ ] `main_app/lib/shared/utils/date_formatter.dart`
- [ ] `main_app/lib/shared/utils/currency_formatter.dart`
- [ ] `main_app/lib/shared/utils/image_compressor.dart`
- [ ] `main_app/lib/shared/utils/validators.dart`
- [ ] `main_app/lib/shared/utils/constants.dart`
- [ ] `main_app/lib/shared/utils/platform_detector.dart`

---

## 🎯 Phase 3: Shared Widgets & Components (Day 6)

### 3.1 Reusable UI Components
**Files: 15**
- [ ] `main_app/lib/shared/widgets/buttons/primary_button.dart`
- [ ] `main_app/lib/shared/widgets/buttons/icon_button.dart`
- [ ] `main_app/lib/shared/widgets/cards/stat_card.dart`
- [ ] `main_app/lib/shared/widgets/cards/action_card.dart`
- [ ] `main_app/lib/shared/widgets/cards/product_card.dart`
- [ ] `main_app/lib/shared/widgets/cards/message_card.dart`
- [ ] `main_app/lib/shared/widgets/inputs/text_input_field.dart`
- [ ] `main_app/lib/shared/widgets/inputs/search_field.dart`
- [ ] `main_app/lib/shared/widgets/inputs/price_input.dart`
- [ ] `main_app/lib/shared/widgets/loaders/shimmer_loader.dart`
- [ ] `main_app/lib/shared/widgets/loaders/progress_dialog.dart`
- [ ] `main_app/lib/shared/widgets/errors/error_card.dart`
- [ ] `main_app/lib/shared/widgets/errors/empty_state.dart`
- [ ] `main_app/lib/shared/widgets/banners/offline_banner.dart`
- [ ] `main_app/lib/shared/widgets/dialogs/confirmation_dialog.dart`

### 3.2 Specialized Widgets
**Files: 8**
- [ ] `main_app/lib/shared/widgets/images/cached_image_with_placeholder.dart`
- [ ] `main_app/lib/shared/widgets/images/image_picker_widget.dart`
- [ ] `main_app/lib/shared/widgets/chips/category_chip.dart`
- [ ] `main_app/lib/shared/widgets/chips/veg_nonveg_indicator.dart`
- [ ] `main_app/lib/shared/widgets/charts/bar_chart_widget.dart`
- [ ] `main_app/lib/shared/widgets/charts/line_chart_widget.dart`
- [ ] `main_app/lib/shared/widgets/pdf/pdf_preview_widget.dart`
- [ ] `main_app/lib/shared/widgets/language/language_selector.dart`

**Verification:**
- All widgets render correctly
- Responsive on all screen sizes
- Dark/light mode compatible

---

## 🎯 Phase 4: Authentication Feature (Day 7)

### 4.1 Auth Models & Repository
**Files: 3**
- [ ] `main_app/lib/features/auth/models/admin_model.dart`
- [ ] `main_app/lib/features/auth/models/login_request.dart`
- [ ] `main_app/lib/features/auth/repository/auth_repository.dart`

### 4.2 Auth Providers (Riverpod)
**Files: 2**
- [ ] `main_app/lib/features/auth/providers/auth_provider.dart`
- [ ] `main_app/lib/features/auth/providers/session_provider.dart`

### 4.3 Auth Screens
**Files: 2**
- [ ] `main_app/lib/features/auth/screens/login_screen.dart`
- [ ] `main_app/lib/features/auth/screens/change_password_screen.dart`

**User Flow:**
1. App opens → check local DB for active session
2. No session → show LoginScreen
3. Enter credentials → call AuthRepository.login()
4. Save JWT + admin profile to local DB
5. Navigate to MainShell
6. Logout → clear session, return to LoginScreen

**Verification:**
- Login success/failure states
- Session persistence across app restarts
- Token expiration handling
- Change password flow

---

## 🎯 Phase 5: Menu Management Feature (Days 8-9)

### 5.1 Menu Models & Repository
**Files: 4**
- [ ] `main_app/lib/features/menu/models/category_model.dart`
- [ ] `main_app/lib/features/menu/models/item_model.dart`
- [ ] `main_app/lib/features/menu/repository/menu_repository.dart`
- [ ] `main_app/lib/features/menu/models/menu_sync_data.dart`

### 5.2 Menu Providers
**Files: 2**
- [ ] `main_app/lib/features/menu/providers/categories_provider.dart`
- [ ] `main_app/lib/features/menu/providers/items_provider.dart`

### 5.3 Menu Screens
**Files: 6**
- [ ] `main_app/lib/features/menu/screens/menu_screen.dart` - Main menu grid
- [ ] `main_app/lib/features/menu/screens/category_manager_screen.dart`
- [ ] `main_app/lib/features/menu/screens/category_editor_dialog.dart`
- [ ] `main_app/lib/features/menu/screens/food_item_editor_screen.dart`
- [ ] `main_app/lib/features/menu/widgets/category_tabs.dart`
- [ ] `main_app/lib/features/menu/widgets/item_grid.dart`

**User Flow:**
1. View menu by category tabs
2. Add category → name + Veg/Non-Veg toggle
3. Add item → name, price, image picker, low stock toggle
4. Image cropped 4:3, compressed 80%
5. Save to local DB + sync queue
6. Upload to server when online

**Verification:**
- Category CRUD operations
- Item CRUD with image upload
- Low stock toggle triggers notification
- Offline create/update works
- Sync queue processes correctly

---

## 🎯 Phase 6: Billing Feature (Days 10-12)

### 6.1 Billing Models & Repository
**Files: 6**
- [ ] `main_app/lib/features/billing/models/bill_model.dart`
- [ ] `main_app/lib/features/billing/models/bill_item.dart`
- [ ] `main_app/lib/features/billing/models/bill_template.dart`
- [ ] `main_app/lib/features/billing/models/discount_type.dart`
- [ ] `main_app/lib/features/billing/repository/billing_repository.dart`
- [ ] `main_app/lib/features/billing/models/bill_pdf_data.dart`

### 6.2 Billing Providers
**Files: 3**
- [ ] `main_app/lib/features/billing/providers/bills_provider.dart`
- [ ] `main_app/lib/features/billing/providers/templates_provider.dart`
- [ ] `main_app/lib/features/billing/providers/cart_provider.dart`

### 6.3 Billing Screens
**Files: 10**
- [ ] `main_app/lib/features/billing/screens/billing_screen.dart` - Main billing hub
- [ ] `main_app/lib/features/billing/screens/create_bill_screen.dart` - Add items to cart
- [ ] `main_app/lib/features/billing/screens/select_template_screen.dart`
- [ ] `main_app/lib/features/billing/screens/bill_preview_screen.dart`
- [ ] `main_app/lib/features/billing/screens/bill_history_screen.dart`
- [ ] `main_app/lib/features/billing/screens/bill_detail_screen.dart`
- [ ] `main_app/lib/features/billing/screens/bill_template_editor_screen.dart`
- [ ] `main_app/lib/features/billing/screens/printer_screen.dart`
- [ ] `main_app/lib/features/billing/widgets/cart_summary.dart`
- [ ] `main_app/lib/features/billing/widgets/item_search_list.dart`

### 6.4 PDF Generation
**Files: 2**
- [ ] `main_app/lib/features/billing/services/pdf_generator.dart`
- [ ] `main_app/lib/features/billing/services/pdf_templates.dart`

### 6.5 Printer Integration
**Files: 3**
- [ ] `main_app/lib/features/billing/services/bluetooth_printer_service.dart` - Android
- [ ] `main_app/lib/features/billing/services/windows_printer_service.dart` - Windows
- [ ] `main_app/lib/features/billing/models/printer_config.dart`

**User Flow:**
1. Select items from searchable list
2. Adjust quantities in cart
3. Apply discount (% or ₹)
4. Generate bill → select template
5. Preview PDF with full details
6. Share via WhatsApp/SMS or Print
7. Save to local DB + sync queue

**Printer Flow (Android):**
1. Scan Bluetooth devices
2. Connect to printer
3. Save as default in printer_config
4. Send PDF bytes to printer

**Printer Flow (Windows):**
1. List available Windows printers
2. Select printer
3. Print directly via printing package

**Verification:**
- Cart calculations accurate
- Discount applied correctly
- PDF renders with logo and formatting
- WhatsApp share includes PDF
- Bluetooth printer connects and prints
- Windows printer lists and prints
- Bills saved locally and synced

---

## 🎯 Phase 7: Quick Messages Feature (Day 13)

### 7.1 Messages Models & Repository
**Files: 3**
- [ ] `main_app/lib/features/messages/models/message_template_model.dart`
- [ ] `main_app/lib/features/messages/repository/messages_repository.dart`
- [ ] `main_app/lib/features/messages/models/message_variables.dart`

### 7.2 Messages Providers
**Files: 1**
- [ ] `main_app/lib/features/messages/providers/messages_provider.dart`

### 7.3 Messages Screens
**Files: 3**
- [ ] `main_app/lib/features/messages/screens/messages_screen.dart`
- [ ] `main_app/lib/features/messages/screens/message_editor_screen.dart`
- [ ] `main_app/lib/features/messages/widgets/variable_chips.dart`

**User Flow:**
1. View list of message templates
2. Create new → title + body
3. Insert variables ({customer_name}, {total_amount}, etc.)
4. Live preview with placeholder substitution
5. Swipe to delete or long-press edit
6. Save to local DB + sync

**Verification:**
- Variable insertion at cursor position
- Preview updates in real-time
- CRUD operations work
- Offline support functional

---

## 🎯 Phase 8: Sales Dashboard Feature (Day 14)

### 8.1 Dashboard Models & Repository
**Files: 3**
- [ ] `main_app/lib/features/dashboard/models/sales_stats.dart`
- [ ] `main_app/lib/features/dashboard/models/top_item.dart`
- [ ] `main_app/lib/features/dashboard/repository/dashboard_repository.dart`

### 8.2 Dashboard Providers
**Files: 2**
- [ ] `main_app/lib/features/dashboard/providers/stats_provider.dart`
- [ ] `main_app/lib/features/dashboard/providers/charts_provider.dart`

### 8.3 Dashboard Screens
**Files: 5**
- [ ] `main_app/lib/features/dashboard/screens/dashboard_screen.dart`
- [ ] `main_app/lib/features/dashboard/widgets/stat_cards_row.dart`
- [ ] `main_app/lib/features/dashboard/widgets/daily_chart.dart`
- [ ] `main_app/lib/features/dashboard/widgets/weekly_chart.dart`
- [ ] `main_app/lib/features/dashboard/widgets/monthly_chart.dart`
- [ ] `main_app/lib/features/dashboard/widgets/top_items_list.dart`
- [ ] `main_app/lib/features/dashboard/widgets/custom_date_range_picker.dart`

**User Flow:**
1. View top row: Today's Revenue, Today's Bills, Top Item, Monthly Revenue
2. Switch tabs: Daily (hourly bar chart), Weekly (daily bar chart), Monthly (line chart)
3. Custom date range picker filters all data
4. View top selling items for selected period
5. All data computed from local bills table (items_json parsing)

**Verification:**
- Stats calculated correctly from local DB
- Charts render with fl_chart
- Date filtering works
- Top items ranked correctly
- Zero server calls (fully offline)

---

## 🎯 Phase 9: Notifications Feature (Day 15)

### 9.1 Notifications Models & Repository
**Files: 3**
- [ ] `main_app/lib/features/notifications/models/notification_model.dart`
- [ ] `main_app/lib/features/notifications/repository/notifications_repository.dart`
- [ ] `main_app/lib/features/notifications/models/notification_settings.dart`

### 9.2 Notifications Providers
**Files: 2**
- [ ] `main_app/lib/features/notifications/providers/notifications_provider.dart`
- [ ] `main_app/lib/features/notifications/providers/settings_provider.dart`

### 9.3 Notifications Screens
**Files: 3**
- [ ] `main_app/lib/features/notifications/screens/notifications_screen.dart`
- [ ] `main_app/lib/features/notifications/screens/notification_settings_screen.dart`
- [ ] `main_app/lib/features/notifications/widgets/notification_tile.dart`

**User Flow:**
1. View list of received notifications (unread highlighted)
2. Tap to mark as read
3. Settings: toggle per notification type
4. Set daily summary time with time picker
5. Schedule daily summary notification

**Verification:**
- FCM messages received and logged
- Local notifications display
- Daily summary scheduled correctly
- Settings persist in SharedPreferences

---

## 🎯 Phase 10: Web CMS Feature (Days 16-18)

### 10.1 CMS Models & Repository
**Files: 4**
- [ ] `main_app/lib/features/cms/models/cms_section_model.dart`
- [ ] `main_app/lib/features/cms/models/hero_banner_data.dart`
- [ ] `main_app/lib/features/cms/models/offer_data.dart`
- [ ] `main_app/lib/features/cms/repository/cms_repository.dart`

### 10.2 CMS Providers
**Files: 2**
- [ ] `main_app/lib/features/cms/providers/cms_provider.dart`
- [ ] `main_app/lib/features/cms/providers/drafts_provider.dart`

### 10.3 CMS Screens - Main
**Files: 2**
- [ ] `main_app/lib/features/cms/screens/cms_screen.dart` - Grid of section cards
- [ ] `main_app/lib/features/cms/screens/publish_confirmation_dialog.dart`

### 10.4 CMS Editor Screens (13 editors)
**Files: 13**
- [ ] `main_app/lib/features/cms/editors/hero_banner_editor.dart` - Multi-image, drag reorder, overlay text
- [ ] `main_app/lib/features/cms/editors/offers_editor.dart` - Offer cards with expiry
- [ ] `main_app/lib/features/cms/editors/gallery_editor.dart` - Photo grid, drag reorder
- [ ] `main_app/lib/features/cms/editors/about_editor.dart` - Rich text + photos
- [ ] `main_app/lib/features/cms/editors/contact_editor.dart` - Hours, map link
- [ ] `main_app/lib/features/cms/editors/social_links_editor.dart` - Social media URLs
- [ ] `main_app/lib/features/cms/editors/announcement_editor.dart` - Scrolling text toggle
- [ ] `main_app/lib/features/cms/editors/menu_settings_editor.dart` - Category visibility
- [ ] `main_app/lib/features/cms/editors/footer_editor.dart` - Footer content
- [ ] `main_app/lib/features/cms/editors/color_theme_editor.dart` - Color picker
- [ ] `main_app/lib/features/cms/editors/seo_editor.dart` - Meta tags, favicon
- [ ] `main_app/lib/features/cms/editors/today_special_editor.dart` - Featured item
- [ ] `main_app/lib/features/cms/editors/feedback_viewer_editor.dart` - Rating + list

### 10.5 CMS Widgets
**Files: 4**
- [ ] `main_app/lib/features/cms/widgets/section_card.dart`
- [ ] `main_app/lib/features/cms/widgets/image_uploader.dart`
- [ ] `main_app/lib/features/cms/widgets/drag_reorder_list.dart`
- [ ] `main_app/lib/features/cms/widgets/color_picker_dialog.dart`

**User Flow:**
1. View grid of CMS sections
2. Edit any section → specific editor screen
3. Changes saved as drafts locally
4. "Publish" button appears when drafts exist
5. Publish sends all drafts to API
6. Clear draft flag on success

**Verification:**
- All 13 section types editable
- Image uploads work with compression
- Drag-to-reorder functional
- Draft state persists
- Publish sends correct data structure

---

## 🎯 Phase 11: Settings Feature (Day 19)

### 11.1 Settings Models & Repository
**Files: 2**
- [ ] `main_app/lib/features/settings/models/settings_model.dart`
- [ ] `main_app/lib/features/settings/repository/settings_repository.dart`

### 11.2 Settings Providers
**Files: 1**
- [ ] `main_app/lib/features/settings/providers/settings_provider.dart`

### 11.3 Settings Screens
**Files: 3**
- [ ] `main_app/lib/features/settings/screens/settings_screen.dart`
- [ ] `main_app/lib/features/settings/screens/printer_management_screen.dart`
- [ ] `main_app/lib/features/settings/screens/sync_status_screen.dart`

**Settings Sections:**
- Admin profile (username, Change Password)
- Sync section (last sync time, Sync Now button, progress)
- Notification preferences
- Printer management (scan, forget)
- App info (version, backend URL)
- Logout button

**Verification:**
- All settings editable
- Printer scan works
- Sync status displays correctly
- Logout clears session

---

## 🎯 Phase 12: App Shell & Navigation (Day 20)

### 12.1 Main Navigation
**Files: 3**
- [ ] `main_app/lib/features/shell/main_shell.dart` - Bottom nav for admin app
- [ ] `main_app/lib/features/shell/web_shell.dart` - Persistent layout for web
- [ ] `main_app/lib/features/shell/navigation_router.dart` - GoRouter configuration

### 12.2 Navigation Items
**Admin App Tabs:**
- [ ] Dashboard
- [ ] Menu
- [ ] Billing
- [ ] Messages
- [ ] CMS
- [ ] Notifications
- [ ] Settings

**Web App Routes:**
- `/` → Home
- `/menu` → Menu
- `/offers` → Offers
- `/gallery` → Gallery
- `/about` → About
- `/contact` → Contact

**Verification:**
- Tab navigation works smoothly
- Deep linking configured
- Web routes respond correctly
- Back button handled properly

---

## 🎯 Phase 13: Web App - Public Pages (Days 21-23)

### 13.1 Web Localization
**Files: 4**
- [ ] `main_app/lib/features/web/localization/app_localizations.dart`
- [ ] `main_app/lib/features/web/localization/localization_delegate.dart`
- [ ] `main_app/assets/translations/en.json` - English translations
- [ ] `main_app/assets/translations/hi.json` - Hindi translations

### 13.2 Web Pages
**Files: 6**
- [ ] `main_app/lib/features/web/pages/home_web_page.dart`
- [ ] `main_app/lib/features/web/pages/menu_web_page.dart`
- [ ] `main_app/lib/features/web/pages/offers_web_page.dart`
- [ ] `main_app/lib/features/web/pages/gallery_web_page.dart`
- [ ] `main_app/lib/features/web/pages/about_web_page.dart`
- [ ] `main_app/lib/features/web/pages/contact_web_page.dart`

### 13.3 Web Components
**Files: 8**
- [ ] `main_app/lib/features/web/components/announcement_bar.dart`
- [ ] `main_app/lib/features/web/components/hero_slider.dart`
- [ ] `main_app/lib/features/web/components/todays_special_card.dart`
- [ ] `main_app/lib/features/web/components/offers_carousel.dart`
- [ ] `main_app/lib/features/web/components/menu_preview_grid.dart`
- [ ] `main_app/lib/features/web/components/about_snippet.dart`
- [ ] `main_app/lib/features/web/components/gallery_masonry.dart`
- [ ] `main_app/lib/features/web/components/web_footer.dart`

### 13.4 Web Floating Widgets
**Files: 3**
- [ ] `main_app/lib/features/web/widgets/floating_whatsapp_button.dart`
- [ ] `main_app/lib/features/web/widgets/floating_feedback_button.dart`
- [ ] `main_app/lib/features/web/widgets/feedback_modal.dart`

### 13.5 Web Animations
**Files: 2**
- [ ] `main_app/lib/features/web/animations/scroll_fade_in.dart`
- [ ] `main_app/lib/features/web/animations/parallax_effect.dart`

**Home Page Sections (in order):**
1. Announcement Bar (scrolling text if enabled)
2. Hero Slider (PageView with timer, overlay text + CTA)
3. Today's Special (highlighted card)
4. Offers Section (horizontal scroll)
5. Menu Preview (first 8 items, "View Full Menu" button)
6. About Snippet (text + photo)
7. Gallery Preview (masonry grid of 6 images)
8. Feedback Section (average rating + feedback widget)

**Menu Page:**
- Category filter bar (horizontal scroll mobile, row desktop)
- Food grid: 2 cols mobile, 3 tablet, 4 desktop
- Item card: image, name, price, veg/non-veg dot
- Search bar filters by name in real-time

**Gallery Page:**
- Responsive masonry grid
- Tap → full-screen lightbox with navigation

**Contact Page:**
- Phone, address, working hours with open/closed indicator
- Map button opens Maps URL

**Verification:**
- All pages responsive (mobile/tablet/desktop)
- Scroll animations trigger correctly
- Language selector persists in localStorage
- Feedback widget submits to API
- WhatsApp button opens chat
- Images cached with shimmer placeholders

---

## 🎯 Phase 14: Asset Configuration (Day 24)

### 14.1 Images & Icons
**Files to Prepare:**
- [ ] `main_app/assets/images/app_logo.png` (512×512 PNG transparent)
- [ ] `main_app/assets/images/splash_logo.png`
- [ ] `main_app/assets/icons/` - Custom SVG icons if needed
- [ ] `main_app/web/favicon.png`
- [ ] `main_app/windows/runner/resources/app_icon.ico`

### 14.2 Configuration Files
**Files:**
- [ ] `main_app/android/app/google-services.json` - Firebase config
- [ ] `main_app/android/key.properties` - Release keystore
- [ ] `main_app/flutter_native_splash.yaml` - Splash screen config
- [ ] `main_app/flutter_launcher_icons.yaml` - App icon config

### 14.3 Run Icon/Splash Generators
```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

---

## 🎯 Phase 15: Testing & Quality Assurance (Days 25-27)

### 15.1 Unit Tests
**Target: 80% coverage on repositories and services**
- [ ] `test/unit/auth_repository_test.dart`
- [ ] `test/unit/menu_repository_test.dart`
- [ ] `test/unit/billing_repository_test.dart`
- [ ] `test/unit/dashboard_repository_test.dart`
- [ ] `test/unit/sync_service_test.dart`
- [ ] `test/unit/pdf_generator_test.dart`

### 15.2 Widget Tests
- [ ] `test/widget/login_screen_test.dart`
- [ ] `test/widget/create_bill_screen_test.dart`
- [ ] `test/widget/menu_screen_test.dart`
- [ ] `test/widget/dashboard_screen_test.dart`
- [ ] `test/widget/web_home_page_test.dart`

### 15.3 Integration Tests
- [ ] `test/integration/login_flow_test.dart`
- [ ] `test/integration/create_bill_flow_test.dart`
- [ ] `test/integration/sync_flow_test.dart`
- [ ] `test/integration/web_feedback_flow_test.dart`

### 15.4 Manual Testing Checklist

**Backend:**
- [ ] All API endpoints return correct status codes
- [ ] Authentication required/optional endpoints work correctly
- [ ] File uploads compress and save correctly
- [ ] FCM notifications send successfully
- [ ] Database constraints enforced

**Admin App - Android:**
- [ ] Login/logout flow
- [ ] Menu CRUD with images
- [ ] Bill creation, preview, share, print
- [ ] Bluetooth printer connection
- [ ] Dashboard charts render
- [ ] CMS editing and publishing
- [ ] Notifications received
- [ ] Offline mode (airplane mode testing)
- [ ] Sync after reconnection

**Admin App - Windows:**
- [ ] All features work on Windows
- [ ] Windows printer integration
- [ ] Window resizing responsive

**Web App:**
- [ ] All pages load correctly
- [ ] Responsive on mobile/tablet/desktop
- [ ] Language switching works
- [ ] Feedback submission works
- [ ] WhatsApp button functional
- [ ] Scroll animations smooth
- [ ] Images lazy load with placeholders

---

## 🎯 Phase 16: Build & Deployment (Day 28)

### 16.1 Backend Deployment
```bash
# On server
cd backend/
composer install
chmod 755 uploads/ uploads/* uploads/*/*
mysql -u root -p < config/schema.sql
# Edit config/database.php and config/app_config.php
```

### 16.2 Flutter Web Build
```bash
cd main_app/
flutter build web --release --base-href /
# Copy build/web/ contents to backend/web_app/
```

### 16.3 Flutter Android Build
```bash
cd main_app/
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 16.4 Flutter Windows Build
```bash
cd main_app/
flutter build windows --release
# Distribute: build/windows/x64/runner/Release/
```

### 16.5 Final Verification
- [ ] Web app loads at domain root
- [ ] Android APK installs and runs
- [ ] Windows executable runs
- [ ] All platforms connect to backend
- [ ] Default admin login works
- [ ] Sample data can be created

---

## 📊 Summary Statistics

| Phase | Description | Files | Days | Priority |
|-------|-------------|-------|------|----------|
| 0 | Foundation Setup | 8 | 1 | Critical |
| 1 | Backend API | 12 | 2 | Critical |
| 2 | Flutter Core | 25+ | 2 | Critical |
| 3 | Shared Widgets | 23 | 1 | High |
| 4 | Authentication | 7 | 1 | Critical |
| 5 | Menu Management | 12 | 2 | High |
| 6 | Billing | 21 | 3 | Critical |
| 7 | Quick Messages | 7 | 1 | Medium |
| 8 | Sales Dashboard | 9 | 1 | High |
| 9 | Notifications | 8 | 1 | Medium |
| 10 | Web CMS | 24 | 3 | High |
| 11 | Settings | 6 | 1 | Medium |
| 12 | Navigation | 3 | 1 | Critical |
| 13 | Web App Pages | 23 | 3 | Critical |
| 14 | Assets | 6 | 1 | Medium |
| 15 | Testing | 15+ | 3 | High |
| 16 | Deployment | - | 1 | Critical |

**Total:** ~210 files, ~28 days of focused development

---

## 🔧 Development Environment Setup

### Required Software
- PHP 8.1+ with MySQL 8.0+
- Composer
- Flutter SDK 3.19+
- Android Studio / VS Code
- Firebase CLI
- Git

### Recommended Extensions
- PHP Intelephense (VS Code)
- Dart/Flutter extensions
- MySQL Workbench
- Postman (API testing)

---

## ⚠️ Critical Path Items

These must be completed in order before other features can be built:

1. **Backend Database Schema** (Phase 0) - All tables must exist first
2. **Backend Auth Endpoints** (Phase 1.1) - Required for all admin app features
3. **Flutter Database Layer** (Phase 2.3) - All features depend on local DB
4. **Flutter Network Layer** (Phase 2.4) - Required for API communication
5. **Sync Engine** (Phase 2.5) - Enables offline-first architecture
6. **Authentication Feature** (Phase 4) - Gatekeeper for all admin features
7. **Navigation Shell** (Phase 12) - Required to access all features

---

## 🎯 Success Criteria

The project is complete when:

✅ All 180-220 files created with zero placeholder code  
✅ Backend serves all endpoints with real database operations  
✅ Admin app works fully offline with sync-on-reconnect  
✅ Web app displays dynamic CMS content from backend  
✅ Bill printing works on Android (Bluetooth) and Windows  
✅ All error/loading/empty states handled with appropriate UI  
✅ No hardcoded demo data anywhere in the application  
✅ Passes all manual testing scenarios  
✅ Builds successfully for Android, Windows, and Web  
✅ Deployed and runnable end-to-end  

---

## 📝 Notes for Implementation

1. **Always build backend endpoints first** before implementing corresponding Flutter features
2. **Test each API endpoint with Postman** before connecting to Flutter
3. **Implement repository pattern strictly** - UI never calls API or DB directly
4. **Use Riverpod for all state** - no setState except purely local UI
5. **Write Drift DAOs before building feature screens**
6. **Test offline mode early and often** - use airplane mode
7. **Build shared widgets incrementally** as needed by features
8. **Keep web app separate from admin app** - different user experiences
9. **Commit frequently** with descriptive messages per feature
10. **Update this plan** if scope changes or new requirements emerge

---

**Ready to begin implementation. Start with Phase 0.**
