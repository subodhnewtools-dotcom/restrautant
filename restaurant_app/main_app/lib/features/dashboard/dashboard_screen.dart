import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/billing_repository.dart';
import '../../shared/widgets/offline_banner.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Main navigation shell for the admin app
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MenuScreen(),
    const BillingScreen(),
    const MessagesScreen(),
    const CmsScreen(),
    const NotificationsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          const OfflineBanner(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.web_outlined),
            selectedIcon: Icon(Icons.web),
            label: 'CMS',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingRepo = ref.read(billingRepositoryProvider);
    
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(selfStatsProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Stats Grid
            FutureBuilder<Map<String, dynamic>>(
              future: billingRepo.getTodayStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return ErrorWidget(snapshot.error);
                }
                final stats = snapshot.data ?? {};
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      title: "Today's Revenue",
                      value: '₹${stats['revenue'] ?? 0}',
                      icon: Icons.currency_rupee,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: "Today's Bills",
                      value: '${stats['count'] ?? 0}',
                      icon: Icons.receipt,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Top Item',
                      value: stats['topItem'] ?? '-',
                      icon: Icons.star,
                      color: Colors.green,
                      isText: true,
                    ),
                    _StatCard(
                      title: 'Monthly Revenue',
                      value: '₹${stats['monthlyRevenue'] ?? 0}',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Charts Section
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Daily'),
                      Tab(text: 'Weekly'),
                      Tab(text: 'Monthly'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildDailyChart(),
                        _buildWeeklyChart(),
                        _buildMonthlyChart(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Hourly Revenue Chart',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Data from local bills',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Weekly Revenue Chart',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Monthly Trend Chart',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isText;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isText ? 14 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MENU SCREEN
// ============================================================================

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuRepo = ref.read(menuRepositoryProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'All Items'),
              Tab(text: 'Categories'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMenuItemsList(ref, menuRepo),
                _buildCategoriesList(ref, menuRepo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsList(WidgetRef ref, dynamic menuRepo) {
    return FutureBuilder<List<dynamic>>(
      future: menuRepo.getAllItemsWithCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No menu items yet', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Item'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _MenuItemCard(
              item: item,
              onTap: () => _showEditItemDialog(context, ref, item),
              onDelete: () => _deleteItem(ref, item['id']),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesList(WidgetRef ref, dynamic menuRepo) {
    return FutureBuilder<List<dynamic>>(
      future: menuRepo.getAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final categories = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: category['type'] == 'veg' ? Colors.green : Colors.red,
                  child: const Icon(Icons.category, color: Colors.white),
                ),
                title: Text(category['name']),
                subtitle: Text('${category['itemCount'] ?? 0} items'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditCategoryDialog(context, ref, category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCategory(ref, category['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    // Implementation for adding new item
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add item dialog - to be implemented')),
    );
  }

  void _showEditItemDialog(BuildContext context, WidgetRef ref, dynamic item) {
    // Implementation for editing item
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${item['name']} - to be implemented')),
    );
  }

  void _deleteItem(WidgetRef ref, int itemId) {
    ref.read(billingRepositoryProvider).deleteItem(itemId);
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, dynamic category) {
    // Implementation for editing category
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${category['name']} - to be implemented')),
    );
  }

  void _deleteCategory(WidgetRef ref, int categoryId) {
    ref.read(menuRepositoryProvider).deleteCategory(categoryId);
  }
}

class _MenuItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MenuItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item['imagePath'] != null && item['imagePath'].isNotEmpty)
                    Image.file(
                      File(item['imagePath']),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item['type'] == 'veg' ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['type'] == 'veg' ? Icons.check_circle : Icons.remove,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  if (item['isLowStock'] == true || item['isLowStock'] == 1)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Low Stock',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item['price']}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.restaurant, color: Colors.grey[400], size: 48),
    );
  }
}

// ============================================================================
// BILLING SCREEN
// ============================================================================

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _BillingActionCard(
                title: 'Create Bill',
                icon: Icons.add_shopping_cart,
                color: Colors.orange,
                onTap: () => _navigateToCreateBill(context),
              ),
              _BillingActionCard(
                title: 'Bill History',
                icon: Icons.history,
                color: Colors.blue,
                onTap: () => _navigateToBillHistory(context),
              ),
              _BillingActionCard(
                title: 'Templates',
                icon: Icons.description,
                color: Colors.green,
                onTap: () => _navigateToTemplates(context),
              ),
              _BillingActionCard(
                title: 'Create Template',
                icon: Icons.add_circle_outline,
                color: Colors.purple,
                onTap: () => _navigateToCreateTemplate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToCreateBill(BuildContext context) {
    // Navigate to create bill screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Bill - to be implemented')),
    );
  }

  void _navigateToBillHistory(BuildContext context) {
    // Navigate to bill history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill History - to be implemented')),
    );
  }

  void _navigateToTemplates(BuildContext context) {
    // Navigate to templates
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates - to be implemented')),
    );
  }

  void _navigateToCreateTemplate(BuildContext context) {
    // Navigate to create template
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Template - to be implemented')),
    );
  }
}

class _BillingActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BillingActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGES SCREEN
// ============================================================================

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesRepo = ref.read(messagesRepositoryProvider);

    return Column(
      children: [
        AppBar(
          title: const Text('Quick Messages'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateMessageDialog(context, ref),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: messagesRepo.getAllTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No message templates', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateMessageDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Message'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Dismissible(
                    key: Key(message['id'].toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => messagesRepo.deleteTemplate(message['id']),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(message['title']),
                        subtitle: Text(
                          message['body'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditMessageDialog(context, ref, message),
                        ),
                        onTap: () => _copyMessage(context, message),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateMessageDialog(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create message dialog - to be implemented')),
    );
  }

  void _showEditMessageDialog(BuildContext context, WidgetRef ref, dynamic message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${message['title']} - to be implemented')),
    );
  }

  void _copyMessage(BuildContext context, dynamic message) {
    // Copy message to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: ${message['body']}')),
    );
  }
}

// ============================================================================
// CMS SCREEN
// ============================================================================

class CmsScreen extends ConsumerWidget {
  const CmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmsRepo = ref.read(cmsRepositoryProvider);

    return Column(
      children: [
        AppBar(
          title: const Text('Web CMS'),
          actions: [
            IconButton(
              icon: const Icon(Icons.publish),
              onPressed: () => _publishChanges(context, ref),
              tooltip: 'Publish Changes',
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: cmsRepo.getAllSections(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final sections = snapshot.data ?? {};
              final sectionKeys = [
                'hero_banner', 'offers', 'about_us', 'gallery', 
                'contact', 'social_links', 'announcement_bar',
                'menu_settings', 'footer', 'color_theme', 'seo', 'today_special'
              ];

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sectionKeys.length,
                itemBuilder: (context, index) {
                  final key = sectionKeys[index];
                  final hasChanges = false; // Check local drafts
                  return _CmsSectionCard(
                    title: _formatSectionTitle(key),
                    icon: _getSectionIcon(key),
                    hasChanges: hasChanges,
                    onTap: () => _openEditor(context, ref, key),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatSectionTitle(String key) {
    return key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  IconData _getSectionIcon(String key) {
    switch (key) {
      case 'hero_banner': return Icons.image;
      case 'offers': return Icons.local_offer;
      case 'about_us': return Icons.info;
      case 'gallery': return Icons.photo_library;
      case 'contact': return Icons.contact_phone;
      case 'social_links': return Icons.share;
      case 'announcement_bar': return Icons.campaign;
      case 'menu_settings': return Icons.menu_book;
      case 'footer': return Icons.format_align_center;
      case 'color_theme': return Icons.palette;
      case 'seo': return Icons.search;
      case 'today_special': return Icons.star;
      default: return Icons.article;
    }
  }

  void _openEditor(BuildContext context, WidgetRef ref, String sectionKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit $sectionKey - to be implemented')),
    );
  }

  void _publishChanges(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publishing changes - to be implemented')),
    );
  }
}

class _CmsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool hasChanges;
  final VoidCallback onTap;

  const _CmsSectionCard({
    required this.title,
    required this.icon,
    required this.hasChanges,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (hasChanges)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATIONS SCREEN
// ============================================================================

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppBar(
          title: const Text('Notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllAsRead(ref),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: ref.read(notificationsRepositoryProvider).getAllNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isUnread = notif['isRead'] == false || notif['isRead'] == 0;
                  return ListTile(
                    leading: Icon(
                      isUnread ? Icons.notifications_active : Icons.notifications,
                      color: isUnread ? Colors.orange : Colors.grey,
                    ),
                    title: Text(
                      notif['title'],
                      style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: Text(notif['body']),
                    trailing: Text(
                      _formatTime(notif['createdAt']),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () => _markAsRead(ref, notif['id']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  void _markAsRead(WidgetRef ref, int id) {
    ref.read(notificationsRepositoryProvider).markAsRead(id);
  }

  void _markAllAsRead(WidgetRef ref) {
    ref.read(notificationsRepositoryProvider).markAllAsRead();
  }
}

// ============================================================================
// SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);
    final session = authRepo.getActiveSession();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(session?['username'] ?? 'Admin'),
                    subtitle: const Text('Administrator'),
                    trailing: ElevatedButton(
                      onPressed: () => _changePassword(context, ref),
                      child: const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sync Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Last Sync'),
                    subtitle: const Text('Today, 10:30 AM'),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _syncNow(ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Printer Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Printer', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.print),
                    title: const Text('Default Printer'),
                    subtitle: const Text('Not configured'),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _scanPrinters(context),
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud),
                    title: const Text('Backend URL'),
                    subtitle: const Text('https://your-restaurant.com/api'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password dialog - to be implemented')),
    );
  }

  void _syncNow(WidgetRef ref) {
    ref.read(syncServiceProvider).syncNow();
  }

  void _scanPrinters(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning for printers...')),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authRepositoryProvider).logout();
              Navigator.pop(context);
              // Navigate to login
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
