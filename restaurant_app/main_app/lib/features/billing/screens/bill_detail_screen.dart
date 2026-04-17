import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/bill_dao.dart';
import '../../shared/widgets/app_card.dart';

class BillDetailScreen extends ConsumerWidget {
  final int billId;

  const BillDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<BillsCompanion>(
      future: ref.read(billDaoProvider).getById(billId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bill Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Bill not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final bill = snapshot.data!;
        return _BillDetailContent(bill: bill);
      },
    );
  }
}

class _BillDetailContent extends StatelessWidget {
  final BillsCompanion bill;

  const _BillDetailContent({required this.bill});

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality can be added here
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Print functionality can be added here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill #${bill.id}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(bill.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${bill.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                if (bill.customerName?.isNotEmpty == true) ...[
                  _buildInfoRow('Customer', bill.customerName!),
                ],
                if (bill.phone?.isNotEmpty == true) ...[
                  _buildInfoRow('Phone', bill.phone!),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Qty', textAlign: TextAlign.center)),
                    DataColumn(label: Text('Price', textAlign: TextAlign.right)),
                    DataColumn(label: Text('Total', textAlign: TextAlign.right)),
                  ],
                  rows: bill.items.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item.name)),
                      DataCell(
                        Text('${item.quantity}', textAlign: TextAlign.center),
                      ),
                      DataCell(
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          '₹${item.subtotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', '₹${bill.subtotal.toStringAsFixed(2)}'),
                      if (bill.discountValue > 0)
                        _buildSummaryRow(
                          'Discount (${bill.discountType})',
                          '-₹${_calculateDiscountAmount().toStringAsFixed(2)}',
                        ),
                      _buildSummaryRow(
                        'Total',
                        '₹${bill.total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDiscountAmount() {
    if (bill.discountType == 'percent') {
      return bill.subtotal * (bill.discountValue / 100);
    }
    return bill.discountValue;
  }
}
