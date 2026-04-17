import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/bill_template_dao.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';

class BillTemplateEditorScreen extends ConsumerStatefulWidget {
  final int? templateId;

  const BillTemplateEditorScreen({super.key, this.templateId});

  @override
  ConsumerState<BillTemplateEditorScreen> createState() => _BillTemplateEditorScreenState();
}

class _BillTemplateEditorScreenState extends ConsumerState<BillTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandNameController = TextEditingController();
  final _footerTextController = TextEditingController();
  
  File? _logoImage;
  Color _primaryColor = Colors.orange;
  String _fontStyle = 'roboto';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) {
      _loadTemplate();
    }
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      final dao = ref.read(billTemplateDaoProvider);
      final template = await dao.getById(widget.templateId!);
      
      if (template != null) {
        _brandNameController.text = template.brandName ?? '';
        _footerTextController.text = template.footerText ?? '';
        _primaryColor = Color(template.primaryColor);
        _fontStyle = template.fontStyle ?? 'roboto';
        
        if (template.logoPath?.isNotEmpty == true && File(template.logoPath!).existsSync()) {
          setState(() => _logoImage = File(template.logoPath!));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading template: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Logo',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Logo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      
      if (croppedFile != null) {
        // Compress image
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          '${croppedFile.path}.compressed.jpg',
          quality: 80,
          format: CompressFormat.jpeg,
        );
        
        setState(() {
          _logoImage = compressedFile != null ? File(compressedFile.path) : File(croppedFile.path);
        });
      }
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dao = ref.read(billTemplateDaoProvider);
      
      final template = BillTemplatesCompanion.insert(
        brandName: _brandNameController.text.trim(),
        footerText: _footerTextController.text.trim(),
        primaryColor: _primaryColor.value,
        fontStyle: _fontStyle,
        logoPath: _logoImage?.path ?? '',
        createdAt: DateTime.now(),
      );
      
      if (widget.templateId != null) {
        await dao.update(widget.templateId!, template);
      } else {
        await dao.insert(template);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template saved successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving template: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.templateId != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.templateId == null ? 'Create Template' : 'Edit Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickAndCropImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _logoImage != null ? FileImage(_logoImage!) : null,
                          child: _logoImage == null
                              ? const Icon(Icons.add_photo_alternate, size: 48)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickAndCropImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Upload Logo'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Template Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _brandNameController,
                        labelText: 'Brand Name *',
                        hintText: 'Enter restaurant name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Brand name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _footerTextController,
                        labelText: 'Footer Text',
                        hintText: 'Thank you for your visit!',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Primary Color',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _colorOption(Colors.orange),
                          _colorOption(Colors.blue),
                          _colorOption(Colors.green),
                          _colorOption(Colors.red),
                          _colorOption(Colors.purple),
                          _colorOption(Colors.teal),
                          _colorOption(Colors.indigo),
                          _colorOption(Colors.brown),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Font Style',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _fontStyle,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'roboto', child: Text('Roboto')),
                          DropdownMenuItem(value: 'opensans', child: Text('Open Sans')),
                          DropdownMenuItem(value: 'lato', child: Text('Lato')),
                          DropdownMenuItem(value: 'montserrat', child: Text('Montserrat')),
                        ],
                        onChanged: (value) {
                          setState(() => _fontStyle = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Save Template',
                onPressed: _isLoading ? null : _saveTemplate,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    final isSelected = color.value == _primaryColor.value;
    return GestureDetector(
      onTap: () => setState(() => _primaryColor = color),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}
