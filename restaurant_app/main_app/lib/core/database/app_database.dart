import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

// ============================================
// Table: Admin Sessions
// Stores active admin session data locally
// ============================================
class AdminSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get token => text()();
  TextColumn get fullName => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Menu Categories
// Food categories (Veg/Non-Veg)
// ============================================
class MenuCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text().check(isIn(['veg', 'non_veg']))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Menu Items
// Individual food items with images
// ============================================
class MenuItems extends Table {
  IntColumn get id => integer()();
  IntColumn get categoryId => integer()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isVeg => boolean().withDefault(const Constant(true))();
  BoolColumn get isLowStock => boolean().withDefault(const Constant(false))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Bill Templates
// Customizable bill/invoice templates
// ============================================
class BillTemplates extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get brandName => text().withLength(min: 1, max: 150)();
  TextColumn get footerText => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get fontStyle => text().withDefault(const Constant('Arial'))();
  TextColumn get primaryColor => text().withDefault(const Constant('#E8630A'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Bills
// Saved bill records
// ============================================
class Bills extends Table {
  IntColumn get id => integer()();
  TextColumn get billNumber => text().withLength(min: 1, max: 50)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get itemsJson => text()();
  RealColumn get subtotal => real()();
  TextColumn get discountType => text().nullable()();
  RealColumn get discountValue => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  IntColumn get templateId => integer().nullable()();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Message Templates
// Quick message templates for customer communication
// ============================================
class MessageTemplates extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: CMS Content
// Cached CMS sections from server
// ============================================
class CmsContent extends Table {
  TextColumn get sectionKey => text().withLength(min: 1, max: 50)();
  TextColumn get contentJson => text()();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();
  TextColumn get draftJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {sectionKey};
}

// ============================================
// Table: Notifications Log
// Log of all received notifications
// ============================================
class NotificationsLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topic => text().withLength(min: 1, max: 50)();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get body => text()();
  TextColumn get dataJson => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Printer Config
// Saved printer configuration
// ============================================
class PrinterConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 100)();
  TextColumn get deviceName => text().withLength(min: 1, max: 150)();
  TextColumn get deviceType => text().check(isIn(['bluetooth', 'windows']))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Table: Sync Queue
// Queue for offline operations to sync when online
// ============================================
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text().check(isIn(['create', 'update', 'delete']))();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer().nullable()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get payloadJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ============================================
// Database Definition
// ============================================
@DriftDatabase(tables: [
  AdminSessions,
  MenuCategories,
  MenuItems,
  BillTemplates,
  Bills,
  MessageTemplates,
  CmsContent,
  NotificationsLog,
  PrinterConfigs,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
}

// ============================================
// Database Connection
// ============================================
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      throw UnsupportedError('Drift database not supported on web. Use API directly.');
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'restaurant_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    }
  });
}
