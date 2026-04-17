import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';

/// Billing repository - handles all billing operations
class BillingRepository {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final SyncService _syncService;

  BillingRepository(this._db, this._apiClient, this._syncService);

  // ============ Bills ============

  /// Get all bills from local DB
  Future<List<Bill>> getAllBills({DateTime? fromDate, DateTime? toDate}) async {
    return await _db.billsDao.getAll(fromDate: fromDate, toDate: toDate);
  }

  /// Get bill by ID
  Future<Bill?> getBillById(int id) async {
    return await _db.billsDao.getById(id);
  }

  /// Create new bill
  Future<bool> createBill({
    required String customerName,
    String? phone,
    required List<BillItem> items,
    required double subtotal,
    String? discountType,
    double? discountValue,
    required double total,
    int? templateId,
  }) async {
    try {
      // Insert to local DB
      final bill = BillsCompanion.insert(
        customerName: customerName,
        phone: phone ?? '',
        itemsJson: jsonEncode(items.map((i) => i.toJson()).toList()),
        subtotal: subtotal,
        discountType: discountType ?? 'none',
        discountValue: discountValue ?? 0.0,
        total: total,
        templateId: templateId,
        synced: 0,
      );

      final billId = await _db.billsDao.insert(bill);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        entityType: 'bill',
        operation: 'CREATE',
        data: {
          'customer_name': customerName,
          'phone': phone ?? '',
          'items': items.map((i) => i.toJson()).toList(),
          'subtotal': subtotal,
          'discount_type': discountType ?? 'none',
          'discount_value': discountValue ?? 0.0,
          'total': total,
          'template_id': templateId,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete bill
  Future<bool> deleteBill(int id) async {
    try {
      // Get bill for server ID
      final bill = await _db.billsDao.getById(id);
      
      // Delete from local DB
      await _db.billsDao.deleteById(id);

      // Add to sync queue
      if (bill?.serverId != null) {
        await _syncService.addToSyncQueue(
          entityType: 'bill',
          operation: 'DELETE',
          data: {},
          serverId: bill!.serverId,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get today's revenue
  Future<double> getTodayRevenue() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final bills = await _db.billsDao.getAll(fromDate: today);
    return bills.fold(0.0, (sum, bill) => sum + bill.total);
  }

  /// Get monthly revenue
  Future<double> getMonthlyRevenue() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    
    final bills = await _db.billsDao.getAll(fromDate: firstDay);
    return bills.fold(0.0, (sum, bill) => sum + bill.total);
  }

  /// Get bills count for today
  Future<int> getTodayBillsCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final bills = await _db.billsDao.getAll(fromDate: today);
    return bills.length;
  }

  /// Get top selling item
  Future<Map<String, dynamic>?> getTopSellingItem({DateTime? fromDate, DateTime? toDate}) async {
    final bills = await _db.billsDao.getAll(fromDate: fromDate, toDate: toDate);
    
    Map<String, Map<String, dynamic>> itemCounts = {};
    
    for (var bill in bills) {
      final items = List<Map<String, dynamic>>.from(jsonDecode(bill.itemsJson));
      for (var item in items) {
        final name = item['name'] as String;
        if (itemCounts.containsKey(name)) {
          itemCounts[name]!['quantity'] = (itemCounts[name]!['quantity'] as int) + (item['quantity'] as int);
        } else {
          itemCounts[name] = {
            'name': name,
            'quantity': item['quantity'] as int,
          };
        }
      }
    }
    
    if (itemCounts.isEmpty) return null;
    
    var topItem = itemCounts.values.reduce((a, b) => 
      (a['quantity'] as int) > (b['quantity'] as int) ? a : b
    );
    
    return topItem;
  }

  /// Get revenue by hour for today
  Future<List<Map<String, dynamic>>> getRevenueByHour() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final bills = await _db.billsDao.getAll(fromDate: today);
    
    List<Map<String, dynamic>> hourlyData = List.generate(24, (index) => {
      'hour': index,
      'revenue': 0.0,
      'count': 0,
    });
    
    for (var bill in bills) {
      final hour = bill.createdAt.hour;
      hourlyData[hour]['revenue'] = (hourlyData[hour]['revenue'] as double) + bill.total;
      hourlyData[hour]['count'] = (hourlyData[hour]['count'] as int) + 1;
    }
    
    return hourlyData;
  }

  /// Get revenue by day for last 7 days
  Future<List<Map<String, dynamic>>> getRevenueByDay() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startOfDay = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
    
    final bills = await _db.billsDao.getAll(fromDate: startOfDay);
    
    List<Map<String, dynamic>> dailyData = List.generate(7, (index) {
      final date = sevenDaysAgo.add(Duration(days: index));
      return {
        'date': date,
        'dayName': _getDayName(date),
        'revenue': 0.0,
        'count': 0,
      };
    });
    
    for (var bill in bills) {
      final billDate = DateTime(bill.createdAt.year, bill.createdAt.month, bill.createdAt.day);
      final diff = billDate.difference(startOfDay).inDays;
      if (diff >= 0 && diff < 7) {
        dailyData[diff]['revenue'] = (dailyData[diff]['revenue'] as double) + bill.total;
        dailyData[diff]['count'] = (dailyData[diff]['count'] as int) + 1;
      }
    }
    
    return dailyData;
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // ============ Bill Templates ============

  /// Get all templates
  Future<List<BillTemplate>> getAllTemplates() async {
    return await _db.templatesDao.getAll();
  }

  /// Get template by ID
  Future<BillTemplate?> getTemplateById(int id) async {
    return await _db.templatesDao.getById(id);
  }

  /// Create template
  Future<bool> createTemplate({
    required String brandName,
    String? footerText,
    String? logoPath,
    String? fontStyle,
    String? accentColor,
  }) async {
    try {
      final template = BillTemplatesCompanion.insert(
        brandName: brandName,
        footerText: footerText ?? '',
        logoUrl: logoPath ?? '',
        fontStyle: fontStyle ?? 'default',
        accentColor: accentColor ?? '#E8630A',
        synced: 0,
      );

      await _db.templatesDao.insert(template);

      // Add to sync queue with logo upload
      await _syncService.addToSyncQueue(
        entityType: 'bill_template',
        operation: 'CREATE',
        data: {
          'brand_name': brandName,
          'footer_text': footerText ?? '',
          'font_style': fontStyle ?? 'default',
          'accent_color': accentColor ?? '#E8630A',
        },
        localImagePath: logoPath,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update template
  Future<bool> updateTemplate({
    required int id,
    String? brandName,
    String? footerText,
    String? logoPath,
    String? fontStyle,
    String? accentColor,
  }) async {
    try {
      final existing = await _db.templatesDao.getById(id);
      if (existing == null) return false;

      await _db.templatesDao.update(
        BillTemplatesCompanion(
          id: Value(id),
          brandName: brandName != null ? Value(brandName) : const Value.absent(),
          footerText: footerText != null ? Value(footerText) : const Value.absent(),
          logoUrl: logoPath != null ? Value(logoPath) : const Value.absent(),
          fontStyle: fontStyle != null ? Value(fontStyle) : const Value.absent(),
          accentColor: accentColor != null ? Value(accentColor) : const Value.absent(),
          synced: const Value(0),
        ),
      );

      await _syncService.addToSyncQueue(
        entityType: 'bill_template',
        operation: 'UPDATE',
        data: {
          if (brandName != null) 'brand_name': brandName,
          if (footerText != null) 'footer_text': footerText,
          if (fontStyle != null) 'font_style': fontStyle,
          if (accentColor != null) 'accent_color': accentColor,
        },
        serverId: existing.serverId,
        localImagePath: logoPath,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete template
  Future<bool> deleteTemplate(int id) async {
    try {
      final template = await _db.templatesDao.getById(id);
      
      await _db.templatesDao.deleteById(id);

      if (template?.serverId != null) {
        await _syncService.addToSyncQueue(
          entityType: 'bill_template',
          operation: 'DELETE',
          data: {},
          serverId: template!.serverId,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

class BillItem {
  final int itemId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  BillItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      itemId: json['item_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}
