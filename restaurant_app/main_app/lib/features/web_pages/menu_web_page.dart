import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/menu_repository.dart';
import '../../shared/widgets/web_menu_item_card.dart';
import '../../shared/utils/app_localizations.dart';

class MenuWebPage extends ConsumerStatefulWidget {
  const MenuWebPage({super.key});

  @override
  ConsumerState<MenuWebPage> createState() => _MenuWebPageState();
}

class _MenuWebPageState extends ConsumerState<MenuWebPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getCategories(List<dynamic> items) {
    final categories = <String>{'all'};
    for (var item in items) {
      if (item.categoryName != null) {
        categories.add(item.categoryName);
      }
    }
    return categories.toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final menuState = ref.watch(menuProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localizations?.t('search_menu') ?? 'Search menu...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FilterChip(
                          label: Text(localizations?.t('all') ?? 'All'),
                          selected: _selectedCategory == 'all',
                          onSelected: (selected) => setState(() => _selectedCategory = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ..._getCategories(menuState.items ?? []).map((category) {
                          if (category == 'all') return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) => setState(() => _selectedCategory = category),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu Grid
            Expanded(
              child: menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuState.error != null
                      ? Center(child: Text('Error: ${menuState.error}'))
                      : menuState.items == null || menuState.items!.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No menu items available',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 300,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: (menuState.items ?? []).where((item) {
                                final matchesCategory = _selectedCategory == 'all' || 
                                    item.categoryName == _selectedCategory;
                                final matchesSearch = _searchQuery.isEmpty ||
                                    item.name.toLowerCase().contains(_searchQuery);
                                return matchesCategory && matchesSearch;
                              }).length,
                              itemBuilder: (context, index) {
                                final filteredItems = (menuState.items ?? []).where((item) {
                                  final matchesCategory = _selectedCategory == 'all' || 
                                      item.categoryName == _selectedCategory;
                                  final matchesSearch = _searchQuery.isEmpty ||
                                      item.name.toLowerCase().contains(_searchQuery);
                                  return matchesCategory && matchesSearch;
                                }).toList();
                                return WebMenuItemCard(item: filteredItems[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
