import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/bill_dao.dart';
import '../../shared/widgets/app_card.dart';

class BillHistoryScreen extends ConsumerStatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  ConsumerState<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends ConsumerState<BillHistoryScreen> {
  DateTime? _selectedDate;
  List<BillsCompanion> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    
    try {
      final dao = ref.read(billDaoProvider);
      if (_selectedDate != null) {
        _bills = await dao.getByDate(_selectedDate!);
      } else {
        _bills = await dao.getAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bills: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: _selectedDate == null ? 'Filter by date' : 'Clear filter',
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _selectedDate = null);
                _loadBills();
              },
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedDate == null
                            ? 'No bills yet'
                            : 'No bills for ${_formatDate(_selectedDate!)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bills.length,
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.receipt,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          bill.customerName?.isNotEmpty == true
                              ? bill.customerName!
                              : 'Walk-in Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bill.phone?.isNotEmpty == true)
                              Text('📞 ${bill.phone}'),
                            const SizedBox(height: 4),
                            Text(_formatDateTime(bill.createdAt)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${bill.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${bill.items.length} items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.go('/billing/history/${bill.id}'),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
