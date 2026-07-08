import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../services/admin_product_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];

  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('categories').orderBy('order').get();
      setState(() {
        _categories = snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first.id;
        }
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Compress image
      final File file = File(pickedFile.path);
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/${const Uuid().v4()}.jpg';
      
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, 
        targetPath,
        quality: 70, // 70% quality is usually ~100kb for mobile photos
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile != null) {
        setState(() {
          _images.add(File(compressedFile.path));
        });
      } else {
        // Fallback if compression fails
        setState(() {
          _images.add(file);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product photo')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: (double.parse(_priceController.text.trim()) * 100).toInt(),
        mrp: _mrpController.text.isNotEmpty ? (double.parse(_mrpController.text.trim()) * 100).toInt() : 0,
        categoryId: _selectedCategory ?? 'uncategorized',
        brand: _brandController.text.trim(),
        images: const [], // Images will be uploaded and updated in service
        stock: int.parse(_stockController.text.trim()),
        unit: 'piece',
        tags: const [],
        isActive: true,
        createdAt: DateTime.now(),
      );

      await AdminProductService().addProduct(product, _images);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenHorizontal),
          children: [
            // Image Picker Section
            Text('Product Photos', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border, style: BorderStyle.solid),
                      ),
                      child: Icon(Icons.add_a_photo_rounded, color: context.colors.primary, size: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ..._images.asMap().entries.map((entry) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            AppTextField(
              controller: _nameController,
              label: 'Product Name',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _brandController,
              label: 'Brand',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (_categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: context.colors.surfaceGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            if (_categories.isEmpty)
              const Text('Please add categories first.', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: 'Selling Price (₹)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _mrpController,
                    label: 'MRP (₹)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _stockController,
              label: 'Initial Stock',
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descController,
              label: 'Description',
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Save Product',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
