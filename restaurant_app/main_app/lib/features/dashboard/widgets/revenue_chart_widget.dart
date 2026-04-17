import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { daily, weekly, monthly, custom }

class RevenueChartWidget extends StatelessWidget {
  final List<dynamic> bills;
  final ChartType chartType;
  final DateTimeRange? dateRange;

  const RevenueChartWidget({
    super.key,
    required this.bills,
    required this.chartType,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final data = _prepareData();

    if (data.isEmpty) {
      return const Center(
        child: Text('No data available for selected period'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _getMaxY(data),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '₹${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= data.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getLabel(index),
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value > _getMaxY(data)) return const SizedBox();
                    return Text(
                      '₹${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _getMaxY(data) / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300],
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: data.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              final isHighest = value == data.reduce((a, b) => a > b ? a : b);
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    gradient: LinearGradient(
                      colors: [
                        isHighest ? const Color(0xFFE8630A) : const Color(0xFFE8630A).withOpacity(0.6),
                        isHighest ? const Color(0xFFFF9800) : const Color(0xFFFF9800).withOpacity(0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<double> _prepareData() {
    final now = DateTime.now();
    List<double> data = [];

    switch (chartType) {
      case ChartType.daily:
        // Revenue by hour for today
        data = List.filled(24, 0.0);
        for (var bill in bills) {
          final billDate = DateTime.parse(bill.createdAt);
          if (billDate.year == now.year && 
              billDate.month == now.month && 
              billDate.day == now.day) {
            data[billDate.hour] += bill.total;
          }
        }
        break;

      case ChartType.weekly:
        // Revenue per day for last 7 days
        data = List.filled(7, 0.0);
        for (var i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: 6 - i));
          for (var bill in bills) {
            final billDate = DateTime.parse(bill.createdAt);
            if (billDate.year == date.year && 
                billDate.month == date.month && 
                billDate.day == date.day) {
              data[i] += bill.total;
            }
          }
        }
        break;

      case ChartType.monthly:
        // Daily revenue for current month
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        data = List.filled(daysInMonth, 0.0);
        for (var bill in bills) {
          final billDate = DateTime.parse(bill.createdAt);
          if (billDate.year == now.year && billDate.month == now.month) {
            data[billDate.day - 1] += bill.total;
          }
        }
        break;

      case ChartType.custom:
        if (dateRange == null) return [];
        final days = dateRange!.end.difference(dateRange!.start).inDays + 1;
        data = List.filled(days, 0.0);
        for (var bill in bills) {
          final billDate = DateTime.parse(bill.createdAt);
          if (billDate.isAfter(dateRange!.start.subtract(const Duration(days: 1))) &&
              billDate.isBefore(dateRange!.end.add(const Duration(days: 1)))) {
            final dayIndex = billDate.difference(dateRange!.start).inDays;
            if (dayIndex >= 0 && dayIndex < days) {
              data[dayIndex] += bill.total;
            }
          }
        }
        break;
    }

    return data;
  }

  String _getLabel(int index) {
    switch (chartType) {
      case ChartType.daily:
        return '${index}:00';
      case ChartType.weekly:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[index];
      case ChartType.monthly:
        return '${index + 1}';
      case ChartType.custom:
        if (dateRange == null) return '';
        final date = dateRange!.start.add(Duration(days: index));
        return '${date.day}/${date.month}';
    }
  }

  double _getMaxY(List<double> data) {
    final max = data.reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    return ((max / 1000).ceil() + 1) * 1000;
  }
}
