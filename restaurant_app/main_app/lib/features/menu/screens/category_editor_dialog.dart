import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/menu_providers.dart';

class CategoryEditorDialog extends ConsumerStatefulWidget {
  final dynamic category;

  const CategoryEditorDialog({super.key, this.category});

  @override
  ConsumerState<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends ConsumerState<CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isVeg = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    if (widget.category != null) {
      _isVeg = widget.category!.isVeg;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(menuRepositoryProvider).saveCategory(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        isVeg: _isVeg,
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.category),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter category name';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Vegetarian'),
              subtitle: Text(_isVeg ? 'Vegetarian items only' : 'Includes non-vegetarian'),
              value: _isVeg,
              onChanged: (value) => setState(() => _isVeg = value),
              activeColor: _isVeg ? const Color(0xFF43A047) : const Color(0xFFE53935),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
