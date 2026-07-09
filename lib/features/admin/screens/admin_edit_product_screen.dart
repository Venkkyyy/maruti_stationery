import 'dart:io';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../models/category_model.dart';
import '../../../services/admin_product_service.dart';
import '../../../models/product_model.dart';

class AdminEditProductScreen extends StatefulWidget {
  final String productId;
  const AdminEditProductScreen({super.key, required this.productId});

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(); // In Rupees
  final _mrpController = TextEditingController(); // In Rupees
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isSaving = false;
  ProductModel? _product;

  List<CategoryModel> _categories = [];
  
  List<String> _existingImages = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final catSnap = await FirebaseFirestore.instance.collection('categories').orderBy('order').get();
      _categories = catSnap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();

      final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        _product = ProductModel.fromFirestore(doc);
        _nameController.text = _product!.name;
        _descController.text = _product!.description;
        _priceController.text = (_product!.price / 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        _mrpController.text = (_product!.mrp / 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        _stockController.text = _product!.stock.toString();
        _brandController.text = _product!.brand;
        _existingImages = List<String>.from(_product!.images);
        
        if (_categories.any((c) => c.id == _product!.categoryId)) {
          _selectedCategory = _product!.categoryId;
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first.id;
        }
      }
    } catch (e) {
      debugPrint('Error loading product: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final int pricePaise = (double.parse(_priceController.text.trim()) * 100).toInt();
      final int mrpPaise = _mrpController.text.isNotEmpty 
          ? (double.parse(_mrpController.text.trim()) * 100).toInt() 
          : 0;

      final updates = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': pricePaise,
        'mrp': mrpPaise,
        'categoryId': _selectedCategory,
        'brand': _brandController.text.trim(),
        'stock': int.parse(_stockController.text.trim()),
      };

      if (_newImages.isNotEmpty || _existingImages.length != _product!.images.length) {
        List<String> newUrls = [];
        if (_newImages.isNotEmpty) {
          newUrls = await AdminProductService().uploadImages(_newImages);
        }
        updates['images'] = [..._existingImages, ...newUrls];
      }

      await AdminProductService().updateProduct(widget.productId, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenHorizontal),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Product Photos', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Add Photos'),
                ),
              ],
            ),
            if (_existingImages.isNotEmpty || _newImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _existingImages.length; i++)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_existingImages[i], fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _existingImages.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (int i = 0; i < _newImages.length; i++)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_newImages[i], fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _newImages.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
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
              const Text('Please add categories first.'),
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
              label: 'Current Stock',
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
              text: 'Update Product',
              onPressed: _isSaving ? null : _submit,
              isLoading: _isSaving,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
