# Restaurant App — Project Documentation

## What This Project Is

This is a cross-platform Flutter application for restaurant management with two distinct experiences: an **admin app** (running on Android and Windows) for restaurant staff to manage menus, billing, messages, and view analytics; and a **public web app** (running in browsers) for customers to view the menu, offers, gallery, and contact information. The backend is a PHP REST API with MySQL database. The admin app is offline-first, using SQLite (Drift) for local data storage with bi-directional sync to the server.

---

## Platform Matrix

| Platform | Who Uses It | Auth Required | Key Capability |
|----------|-------------|---------------|----------------|
| Android App | Restaurant Admin/Staff | Yes (JWT) | Full admin features, Bluetooth printing, FCM push notifications, offline mode |
| Windows App | Restaurant Admin/Staff | Yes (JWT) | Full admin features, Windows printer support, offline mode |
| Web App | Customers/Public | No | View menu, offers, gallery, about, contact, submit feedback |

---

## Full Tech Stack

### Flutter App Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management and dependency injection |
| `riverpod_annotation` | Code generation for Riverpod providers |
| `dio` | HTTP client with interceptors for API calls |
| `drift` | SQLite ORM for local database |
| `sqlite3_flutter_libs` | SQLite native bindings for Flutter |
| `path_provider` | Access device file system paths |
| `path` | Path manipulation utilities |
| `shared_preferences` | Persistent key-value storage for settings |
| `image_picker` | Select images from camera or gallery |
| `image_cropper` | Crop images to desired aspect ratio |
| `flutter_image_compress` | Compress images before upload |
| `pdf` | Generate PDF documents for bills |
| `printing` | Print PDFs and share documents |
| `share_plus` | Share content via WhatsApp, SMS, etc. |
| `url_launcher` | Open URLs (maps, phone, whatsapp) |
| `flutter_blue_plus` | Bluetooth LE scanning and communication (Android) |
| `flutter_local_notifications` | Schedule and display local notifications |
| `firebase_core` | Firebase initialization |
| `firebase_messaging` | Receive FCM push notifications |
| `fl_chart` | Render charts for dashboard analytics |
| `connectivity_plus` | Detect network connectivity status |
| `intl` | Internationalization and date formatting |
| `cached_network_image` | Cache and display network images with placeholders |
| `shimmer` | Shimmer loading effect widgets |
| `flutter_svg` | Render SVG images |
| `lottie` | Render Lottie animations |
| `go_router` | Declarative routing and navigation |
| `universal_html` | Access browser localStorage on web |

### Backend Technologies

| Technology | Purpose |
|------------|---------|
| PHP 8.1+ | Server-side API logic |
| MySQL 8.0+ | Relational database |
| Apache 2.4+ / Nginx | Web server |
| Composer | PHP dependency manager |
| `firebase/php-jwt` | JWT token generation and verification |
| GD Library | Image compression and manipulation |

---

## Architecture Pattern

The project follows a **feature-first folder structure**. Each feature module contains:

- `models/` — Data classes (freezed or plain Dart classes)
- `repository/` — Data access layer (calls API and local DB)
- `providers/` — Riverpod providers exposing state to UI
- `screens/` — UI widgets and pages

**Repository Pattern**: UI layers never call API or database directly. All data access goes through repositories, which decide whether to read from local cache or fetch from server based on connectivity and sync status.

```
features/
└── billing/
    ├── models/
    │   ├── bill.dart
    │   └── bill_template.dart
    ├── repository/
    │   └── billing_repository.dart
    ├── providers/
    │   └── billing_providers.dart
    └── screens/
        ├── billing_screen.dart
        ├── create_bill_screen.dart
        └── ...
```

---

## State Management Rules

- **All state is managed via Riverpod.** No `setState()` except for purely local UI widgets (e.g., text field focus, animation controllers).
- Use `StateNotifierProvider` for complex state with multiple actions.
- Use `FutureProvider` for one-time async data fetching.
- Use `StreamProvider` for continuous data streams (e.g., sync status, connectivity).
- Use `Provider` for pure dependencies (repositories, services).
- All providers are annotated with `@riverpod` for code generation where applicable.

---

## Data Flow

```
UI Widget
    ↓ (watches/consumes)
Riverpod Provider
    ↓ (calls)
Repository
    ↓ (decides)
Local DB (Drift) ←→ Sync Queue ←→ API Client (Dio) ←→ PHP Backend ←→ MySQL
```

1. UI requests data via provider.
2. Repository returns cached data from local DB immediately.
3. If online, repository triggers background sync to refresh data from API.
4. Write operations: save to local DB first, add to sync queue, process queue when online.

---

## Local Database Tables (Drift/SQLite)

### `admin_session`
Stores active JWT session.
```sql
CREATE TABLE admin_session (
    id INTEGER PRIMARY KEY,
    admin_id INTEGER NOT NULL,
    username TEXT NOT NULL,
    jwt_token TEXT NOT NULL,
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);
```

### `menu_categories`
```sql
CREATE TABLE menu_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'food',
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_visible INTEGER NOT NULL DEFAULT 1,
    synced INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### `menu_items`
```sql
CREATE TABLE menu_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    description TEXT,
    image_url TEXT,
    local_image_path TEXT,
    is_veg INTEGER NOT NULL DEFAULT 1,
    is_low_stock INTEGER NOT NULL DEFAULT 0,
    is_available INTEGER NOT NULL DEFAULT 1,
    sort_order INTEGER NOT NULL DEFAULT 0,
    synced INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE CASCADE
);
```

### `bill_templates`
```sql
CREATE TABLE bill_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    brand_name TEXT NOT NULL,
    footer_text TEXT,
    logo_url TEXT,
    local_logo_path TEXT,
    font_style TEXT DEFAULT 'sans',
    accent_color TEXT DEFAULT '#E8630A',
    is_default INTEGER NOT NULL DEFAULT 0,
    synced INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### `bills`
```sql
CREATE TABLE bills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    bill_number TEXT NOT NULL,
    customer_name TEXT,
    phone TEXT,
    items_json TEXT NOT NULL,
    subtotal REAL NOT NULL,
    discount_type TEXT DEFAULT 'none',
    discount_value REAL DEFAULT 0,
    total REAL NOT NULL,
    template_id INTEGER,
    payment_method TEXT DEFAULT 'cash',
    synced INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (template_id) REFERENCES bill_templates(id) ON DELETE SET NULL
);
```

### `message_templates`
```sql
CREATE TABLE message_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    variables_json TEXT,
    synced INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### `cms_content`
```sql
CREATE TABLE cms_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    section_key TEXT NOT NULL UNIQUE,
    content_json TEXT NOT NULL,
    is_draft INTEGER NOT NULL DEFAULT 0,
    synced INTEGER NOT NULL DEFAULT 1,
    updated_at INTEGER NOT NULL
);
```

### `notifications_log`
```sql
CREATE TABLE notifications_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    topic TEXT,
    payload TEXT,
    is_read INTEGER NOT NULL DEFAULT 0,
    received_at INTEGER NOT NULL
);
```

### `printer_config`
```sql
CREATE TABLE printer_config (
    id INTEGER PRIMARY KEY,
    device_address TEXT,
    device_name TEXT,
    printer_type TEXT NOT NULL DEFAULT 'bluetooth',
    is_default INTEGER NOT NULL DEFAULT 0
);
```

### `sync_queue`
```sql
CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id INTEGER,
    payload_json TEXT NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
);
```

---

## API Authentication

- All admin API endpoints require a valid JWT token in the `Authorization` header: `Bearer <token>`.
- Public endpoints (menu, CMS sections, feedback submission) do not require authentication.
- Tokens are generated on login and stored in the `admins` table session.
- Logout adds the token to the `token_blacklist` table.
- Token expiry is configurable (default: 7 days).

---

## Sync Engine Logic

The sync engine ensures data consistency between local SQLite and server MySQL.

### On App Launch (Admin App)
1. Check connectivity.
2. If online: call `/api/sync/full_sync` endpoint.
3. Receive JSON with all categories, items, templates, messages, CMS content.
4. Upsert each record into local Drift tables (match by `server_id`).
5. Download any new images referenced in the data.
6. Process `sync_queue`: iterate pending operations, call appropriate API endpoints, delete on success.
7. Update last sync timestamp.

### While Offline
1. All write operations (create, update, delete) save to local DB immediately.
2. Each write also inserts a record into `sync_queue` with operation details.
3. UI updates instantly from local data.
4. No API calls are attempted (ConnectivityInterceptor throws `OfflineException`).

### On Reconnection
1. Connectivity listener triggers `syncService.syncNow()`.
2. Full sync fetches latest server data.
3. Sync queue processor sends all pending operations.
4. Conflicts resolved by "last write wins" based on `updated_at` timestamps.

### Background Sync
- Timer runs every `kSyncIntervalSecs` (default: 300 seconds / 5 minutes).
- Only triggers if app is in foreground and online.
- Silent sync: no UI indication unless errors occur.

---

## Feature Summaries

### Billing
Create itemized bills with dynamic discount calculations. Select from saved templates, preview PDF, share via WhatsApp/SMS, print via Bluetooth (Android) or Windows printers. Bills saved locally and synced to server. Bill history with filtering by date range.

### Menu Manager
Organize menu items into categories (Veg/Non-Veg). Add/edit items with image upload (camera or gallery), auto-crop and compress. Toggle low-stock status. Drag-to-reorder categories. Changes sync to server and reflect on web app.

### Quick Messages
Pre-written message templates for common communications (order confirmation, thank you, feedback request). Insert variables like `{customer_name}`, `{total_amount}`. One-tap copy to clipboard or share.

### Sales Dashboard
Real-time analytics from local bills data. Today's revenue, bill count, top-selling item, monthly totals. Interactive charts: hourly bar chart (daily), daily bar chart (weekly), trend line (monthly). Custom date range picker. Top items ranked list.

### Notifications
FCM push notifications for low stock alerts and daily summaries. Local notification scheduling. Notification inbox with read/unread status. Configurable preferences per notification type.

### Web CMS
Full website content management: hero banner slider, offers, about us, gallery, contact info, social links, announcement bar, menu visibility settings, footer, color theme, SEO metadata, today's special. Draft/publish workflow. Image uploads with drag-to-reorder.

### Bill Printing
Android: Bluetooth scanner lists nearby printers with signal strength. Connect and save default. Send PDF bytes directly to printer. Windows: List system printers via `printing` package. Print dialog with preview.

### Web App
Customer-facing website with responsive design. Sections: announcement bar, hero slider, today's special, offers carousel, menu preview, about snippet, gallery masonry, feedback widget. Multi-language support. Floating WhatsApp and feedback buttons.

### Multi-language
JSON-based translation files (`en.json`, `hi.json`, etc.). Language selector persists in localStorage (web) or SharedPreferences (app). All UI text uses `AppLocalizations.t('key')`. Add new language by copying and translating JSON file.

### Feedback Widget
Floating button on web app opens 5-star rating modal with optional comment (max 200 chars). Submits to `/api/feedback`. CMS feedback viewer shows average rating and individual submissions with delete capability.

---

## File Structure Reference

```
restaurant_app/
├── main_app/                    # Flutter project
│   ├── lib/
│   │   ├── main.dart            # Entry point
│   │   ├── config/
│   │   │   └── app_config.dart  # Base URL, constants
│   │   ├── core/
│   │   │   ├── database/        # Drift tables and DAOs
│   │   │   ├── network/         # Dio client, interceptors
│   │   │   ├── sync/            # Sync engine
│   │   │   └── notifications/   # FCM and local notifications
│   │   ├── features/            # Feature modules
│   │   └── shared/              # Theme, widgets, utils
│   └── assets/
│       └── translations/        # i18n JSON files
│
├── backend/                     # PHP API
│   ├── config/                  # DB and app config
│   ├── core/                    # PDO, Response, Auth, FileUpload
│   ├── api/                     # Endpoint implementations
│   └── uploads/                 # User-uploaded files
│
└── docs/                        # This documentation
```
