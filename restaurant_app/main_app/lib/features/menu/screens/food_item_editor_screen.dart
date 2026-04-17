import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../providers/menu_providers.dart';
import '../models/menu_item_model.dart';

class FoodItemEditorScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final String? categoryId;
  
  const FoodItemEditorScreen({
    super.key,
    this.itemId,
    this.categoryId,
  });

  @override
  ConsumerState<FoodItemEditorScreen> createState() => _FoodItemEditorScreenState();
}

class _FoodItemEditorScreenState extends ConsumerState<FoodItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  bool _isVeg = true;
  bool _isLowStock = false;
  String? _selectedCategoryId;
  File? _imageFile;
  bool _isLoading = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedCategoryId = widget.categoryId;

    if (widget.itemId != null) {
      _loadItem();
    }
  }

  void _loadItem() {
    final item = ref.read(menuRepositoryProvider).getItemById(widget.itemId!);
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _descriptionController.text = item.description ?? '';
      _isVeg = item.isVeg;
      _isLowStock = item.isLowStock ?? false;
      _selectedCategoryId = item.categoryId;
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        _imageFile = File(item.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1440,
      );

      if (pickedFile == null) return;

      // Crop image to 4:3 ratio
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.orange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile == null) return;

      // Compress image to 80% quality
      final dir = await getApplicationDocumentsDirectory();
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        '${dir.path}/food_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        setState(() {
          _imageFile = compressedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: \$e')),
      );
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(menuRepositoryProvider);
      
      final item = MenuItemModel(
        id: widget.itemId,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        isVeg: _isVeg,
        isLowStock: _isLowStock,
        imagePath: _imageFile?.path,
      );

      if (widget.itemId != null) {
        await repository.updateMenuItem(item);
      } else {
        await repository.createMenuItem(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: widget.itemId != null ? 'Edit Item' : 'Add Item',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Preview
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Image Upload Button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Upload Image'),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price Field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Veg/Non-Veg Toggle
            SwitchListTile(
              title: const Text('Vegetarian'),
              subtitle: Text(_isVeg ? 'Marked as Vegetarian' : 'Marked as Non-Vegetarian'),
              value: _isVeg,
              onChanged: (value) => setState(() => _isVeg = value),
              secondary: Icon(
                _isVeg ? Icons.check_circle_outline : Icons.remove_circle_outline,
                color: _isVeg ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            // Low Stock Toggle
            SwitchListTile(
              title: const Text('Low Stock Alert'),
              subtitle: const Text('Enable to receive notifications when stock is low'),
              value: _isLowStock,
              onChanged: (value) => setState(() => _isLowStock = value),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}
