import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_card.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _ActionCard(
                  icon: Icons.add_shopping_cart,
                  title: 'Create Bill',
                  subtitle: 'New order',
                  color: Colors.orange,
                  onTap: () => context.go('/billing/create'),
                ),
                _ActionCard(
                  icon: Icons.history,
                  title: 'Bill History',
                  subtitle: 'View all bills',
                  color: Colors.blue,
                  onTap: () => context.go('/billing/history'),
                ),
                _ActionCard(
                  icon: Icons.palette,
                  title: 'Templates',
                  subtitle: 'Manage templates',
                  color: Colors.green,
                  onTap: () => context.go('/billing/templates'),
                ),
                _ActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'New Template',
                  subtitle: 'Create template',
                  color: Colors.purple,
                  onTap: () => context.go('/billing/templates/create'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Bills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: ref.read(billDaoProvider).getAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bills = snapshot.data ?? [];
                
                if (bills.isEmpty) {
                  return AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bills yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/billing/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Your First Bill'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Show only last 5 bills
                final recentBills = bills.take(5).toList();
                
                return Column(
                  children: [
                    ...recentBills.map((bill) => AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          bill.customerName?.isNotEmpty == true
                              ? bill.customerName!
                              : 'Walk-in Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_formatDate(bill.createdAt)),
                        trailing: Text(
                          '₹${bill.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        onTap: () => context.go('/billing/history/${bill.id}'),
                      ),
                    )),
                    if (bills.length > 5)
                      TextButton(
                        onPressed: () => context.go('/billing/history'),
                        child: const Text('View All Bills'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
