import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../models/banner_model.dart';
import '../../../services/admin_banner_service.dart';

enum BannerLinkType { none, category, product }

class AdminBannerFormScreen extends ConsumerStatefulWidget {
  final BannerModel? existingBanner;

  const AdminBannerFormScreen({super.key, this.existingBanner});

  @override
  ConsumerState<AdminBannerFormScreen> createState() => _AdminBannerFormScreenState();
}

class _AdminBannerFormScreenState extends ConsumerState<AdminBannerFormScreen> {
  final _adminBannerService = AdminBannerService();

  XFile? _imageFile;
  bool _isActive = true;
  bool _isLoading = false;

  BannerLinkType _linkType = BannerLinkType.none;
  String? _selectedCategoryId;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    if (widget.existingBanner != null) {
      _isActive = widget.existingBanner!.isActive;
      if (widget.existingBanner!.targetCategoryId != null) {
        _linkType = BannerLinkType.category;
        _selectedCategoryId = widget.existingBanner!.targetCategoryId;
      } else if (widget.existingBanner!.targetProductId != null) {
        _linkType = BannerLinkType.product;
        _selectedProductId = widget.existingBanner!.targetProductId;
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  Future<void> _saveBanner() async {
    if (_imageFile == null && widget.existingBanner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    final String? targetCategoryId = _linkType == BannerLinkType.category ? _selectedCategoryId : null;
    final String? targetProductId = _linkType == BannerLinkType.product ? _selectedProductId : null;

    setState(() => _isLoading = true);
    try {
      if (widget.existingBanner == null) {
        await _adminBannerService.addBanner(
          _imageFile!,
          _isActive,
          targetCategoryId: targetCategoryId,
          targetProductId: targetProductId,
        );
      } else {
        await _adminBannerService.updateBanner(
          widget.existingBanner!.id,
          _imageFile,
          widget.existingBanner!.imageUrl,
          _isActive,
          targetCategoryId: targetCategoryId,
          targetProductId: targetProductId,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving banner: $e')),
        );
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
        title: Text(widget.existingBanner == null ? 'Add Banner' : 'Edit Banner'),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Banner Image (16:9 ratio recommended)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border.all(color: context.colors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imageFile!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : (widget.existingBanner != null && widget.existingBanner!.imageUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.existingBanner!.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 48, color: context.colors.textSecondary),
                              const SizedBox(height: 8),
                              Text('Tap to select image',
                                  style: TextStyle(color: context.colors.textSecondary)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Active Banner'),
              subtitle: const Text('Show this banner on the home screen'),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            const Divider(height: 32),

            // --- Banner Link Section ---
            Text(
              'Banner Link (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'When a customer taps this banner, where should it go?',
              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Link Type Selector
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  RadioListTile<BannerLinkType>(
                    title: const Text('No Link'),
                    value: BannerLinkType.none,
                    groupValue: _linkType,
                    activeColor: context.colors.primary,
                    onChanged: (val) => setState(() {
                      _linkType = val!;
                      _selectedCategoryId = null;
                      _selectedProductId = null;
                    }),
                  ),
                  Divider(height: 1, color: context.colors.border),
                  RadioListTile<BannerLinkType>(
                    title: const Text('Link to a Category'),
                    value: BannerLinkType.category,
                    groupValue: _linkType,
                    activeColor: context.colors.primary,
                    onChanged: (val) => setState(() {
                      _linkType = val!;
                      _selectedProductId = null;
                    }),
                  ),
                  Divider(height: 1, color: context.colors.border),
                  RadioListTile<BannerLinkType>(
                    title: const Text('Link to a Product'),
                    value: BannerLinkType.product,
                    groupValue: _linkType,
                    activeColor: context.colors.primary,
                    onChanged: (val) => setState(() {
                      _linkType = val!;
                      _selectedCategoryId = null;
                    }),
                  ),
                ],
              ),
            ),

            // --- Category Picker ---
            if (_linkType == BannerLinkType.category) ...[
              const SizedBox(height: 16),
              Text(
                'Select Category',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    hint: const Text('Choose a category'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.colors.border),
                      ),
                    ),
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? doc.id),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedCategoryId = val;
                    }),
                  );
                },
              ),
            ],

            // --- Product Picker ---
            if (_linkType == BannerLinkType.product) ...[
              const SizedBox(height: 16),
              Text(
                'Select Product',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    hint: const Text('Choose a product'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.colors.border),
                      ),
                    ),
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          data['name'] ?? doc.id,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedProductId = val;
                    }),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),
            AppButton(
              text: 'Save Banner',
              onPressed: _saveBanner,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
