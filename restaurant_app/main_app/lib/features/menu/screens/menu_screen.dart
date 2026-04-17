import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_card_widget.dart';
import '../widgets/category_card_widget.dart';
import '../providers/menu_providers.dart';
import 'category_manager_screen.dart';
import 'food_item_editor_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() -> _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> with SingleTickerProviderStateMixin {
  String? _selectedCategoryId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuCategoriesProvider).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);
    final itemsAsync = ref.watch(menuItemsProvider(_selectedCategoryId));

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: 'Menu Manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
            ),
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.restaurant_menu,
              title: 'No Categories',
              message: 'Create your first category to get started',
              actionLabel: 'Create Category',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
              ),
            );
          }

          return Column(
            children: [
              // Category Tabs
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == null;
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategoryId = null);
                          },
                        ),
                      );
                    }
                    final category = categories[index - 1];
                    final isSelected = _selectedCategoryId == category.id;
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategoryId = category.id);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Items Grid
              Expanded(
                child: itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.fastfood,
                        title: 'No Items',
                        message: 'Add food items to this category',
                        actionLabel: 'Add Item',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodItemEditorScreen(categoryId: _selectedCategoryId),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return CategoryCardWidget(
                          title: item.name,
                          subtitle: '₹${item.price}',
                          imageUrl: item.imagePath.isNotEmpty ? item.imagePath : null,
                          isVeg: item.isVeg,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodItemEditorScreen(
                                itemId: item.id,
                                categoryId: item.categoryId,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => ErrorCardWidget(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(menuItemsProvider(_selectedCategoryId)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCardWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(menuCategoriesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodItemEditorScreen(categoryId: _selectedCategoryId),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
