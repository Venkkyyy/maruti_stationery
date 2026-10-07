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
import '../../../models/brand_model.dart';
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
  final _highlightsController = TextEditingController();
  final _variationsController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedBrand;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isReturnable = false;
  bool _isBestSeller = false;
  ProductModel? _product;

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  
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

      final brandSnap = await FirebaseFirestore.instance.collection('brands').orderBy('name').get();
      _brands = brandSnap.docs.map((d) => BrandModel.fromFirestore(d)).toList();

      final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        _product = ProductModel.fromFirestore(doc);
        _nameController.text = _product!.name;
        _descController.text = _product!.description;
        _priceController.text = (_product!.price / 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        _mrpController.text = (_product!.mrp / 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
        _stockController.text = _product!.stock.toString();
        _isReturnable = _product!.isReturnable;
        _isBestSeller = _product!.isBestSeller;
        _existingImages = List<String>.from(_product!.images);
        
        _highlightsController.text = _product!.highlights.join(', ');
        _variationsController.text = _product!.variations.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('\n');
        
        if (_categories.any((c) => c.id == _product!.categoryId)) {
          _selectedCategory = _product!.categoryId;
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first.id;
        }

        if (_product!.brandId != null && _brands.any((b) => b.id == _product!.brandId)) {
          _selectedBrand = _product!.brandId;
        } else if (_brands.isNotEmpty) {
          _selectedBrand = _brands.first.id;
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
    _highlightsController.dispose();
    _variationsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
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

      // Parse highlights
      final highlights = _highlightsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Parse variations
      final variations = <String, List<String>>{};
      final variationLines = _variationsController.text.split('\n');
      for (final line in variationLines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          final key = parts[0].trim();
          final vals = parts[1].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (key.isNotEmpty && vals.isNotEmpty) {
            variations[key] = vals;
          }
        }
      }

      final updates = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': pricePaise,
        'mrp': mrpPaise,
        'categoryId': _selectedCategory,
        'brand': _brands.firstWhere((b) => b.id == _selectedBrand, orElse: () => BrandModel(id: '', name: 'Unknown', logoUrl: '', createdAt: DateTime.now())).name,
        'brandId': _selectedBrand,
        'stock': int.parse(_stockController.text.trim()),
        'isReturnable': _isReturnable,
        'highlights': highlights,
        'variations': variations,
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
            if (_brands.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedBrand,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  filled: true,
                  fillColor: context.colors.surfaceGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                onChanged: (v) => setState(() => _selectedBrand = v),
              ),
            if (_brands.isEmpty)
              const Text('Please add brands first in the Manage Brands section.', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            if (_categories.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
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
            const SizedBox(height: 16),
            AppTextField(
              controller: _highlightsController,
              label: 'Highlights (Comma-separated)',
              hint: 'e.g. Eco friendly, 70 GSM paper',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _variationsController,
              label: 'Variations (Key: val1, val2 per line)',
              hint: 'e.g.\nColor: Red, Blue\nSize: Small, Large',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Returnable Product', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Allow customers to request returns for this product'),
              value: _isReturnable,
              onChanged: (val) => setState(() => _isReturnable = val),
              activeColor: context.colors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Best Seller', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Display this product in the Best Sellers section'),
              value: _isBestSeller,
              onChanged: (val) => setState(() => _isBestSeller = val),
              activeColor: context.colors.primary,
              contentPadding: EdgeInsets.zero,
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
