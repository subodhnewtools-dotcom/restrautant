import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_card_widget.dart';
import '../providers/billing_providers.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/revenue_chart_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: buildAppBar(context, title: 'Sales Dashboard'),
      body: billsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.insights,
              title: 'No Sales Data',
              message: 'Start creating bills to see your sales analytics',
            );
          }

          return Column(
            children: [
              // Stats Cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: stats.when(
                  data: (data) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCardWidget(
                        title: "Today's Revenue",
                        value: '₹${data.todayRevenue.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        color: const Color(0xFFE8630A),
                      ),
                      StatCardWidget(
                        title: "Today's Bills",
                        value: data.todayBills.toString(),
                        icon: Icons.receipt_long,
                        color: const Color(0xFF2196F3),
                      ),
                      StatCardWidget(
                        title: 'Top Item',
                        value: data.topItem ?? '-',
                        icon: Icons.star,
                        color: const Color(0xFFFFC107),
                        fontSize: 14,
                      ),
                      StatCardWidget(
                        title: 'Monthly Revenue',
                        value: '₹${data.monthlyRevenue.toStringAsFixed(0)}',
                        icon: Icons.trending_up,
                        color: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              const Divider(height: 1),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                  Tab(text: 'Custom'),
                ],
              ),

              // Charts
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Daily Chart
                    RevenueChartWidget(
                      bills: bills,
                      chartType: ChartType.daily,
                    ),
                    // Weekly Chart
                    RevenueChartWidget(
                      bills: bills,
                      chartType: ChartType.weekly,
                    ),
                    // Monthly Chart
                    RevenueChartWidget(
                      bills: bills,
                      chartType: ChartType.monthly,
                    ),
                    // Custom Date Range
                    _buildCustomDateRange(bills),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCardWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(billsProvider),
        ),
      ),
    );
  }

  Widget _buildCustomDateRange(List<dynamic> bills) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedDateRange == null
                  ? 'Select Date Range'
                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
            ),
          ),
        ),
        Expanded(
          child: _selectedDateRange == null
              ? const Center(
                  child: Text('Please select a date range to view analytics'),
                )
              : RevenueChartWidget(
                  bills: bills,
                  chartType: ChartType.custom,
                  dateRange: _selectedDateRange,
                ),
        ),
      ],
    );
  }
}
