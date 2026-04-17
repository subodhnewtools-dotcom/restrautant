import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardStats {
  final double todayRevenue;
  final int todayBills;
  final String? topItem;
  final double monthlyRevenue;

  DashboardStats({
    required this.todayRevenue,
    required this.todayBills,
    this.topItem,
    required this.monthlyRevenue,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      todayRevenue: 0,
      todayBills: 0,
      monthlyRevenue: 0,
    );
  }
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  // This will be implemented with actual data from bills
  // For now returning empty stats
  return DashboardStats.empty();
});
