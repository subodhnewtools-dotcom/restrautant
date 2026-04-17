import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_card_widget.dart';
import '../providers/menu_providers.dart';
import '../models/menu_category_model.dart';
import 'category_editor_dialog.dart';

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);

    return Scaffold(
      appBar: buildAppBar(context, title: 'Manage Categories'),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.category,
              title: 'No Categories',
              message: 'Create your first menu category',
              actionLabel: 'Create Category',
              onAction: () => _showEditorDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.isVeg 
                        ? const Color(0xFF43A047) 
                        : const Color(0xFFE53935),
                    child: Icon(
                      category.isVeg ? Icons.eco : Icons.restaurant,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: Text(
                    category.type == 'veg' ? 'Vegetarian' : 'Non-Vegetarian',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditorDialog(context, ref, category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCardWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(menuCategoriesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditorDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditorDialog(BuildContext context, WidgetRef ref, [MenuCategoryModel? category]) {
    showDialog(
      context: context,
      builder: (_) => CategoryEditorDialog(category: category),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MenuCategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will also delete all items in this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(menuRepositoryProvider).deleteCategory(category.id);
              if (context.mounted) Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
