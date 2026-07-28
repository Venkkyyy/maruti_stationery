import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../../models/category_model.dart';
import '../../../services/admin_category_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CategoryFormSheet(),
    );
  }

  void _showEditCategorySheet(BuildContext context, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(existingCategory: cat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        onPressed: () => _showAddCategorySheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final categories = snapshot.data!.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceGrey,
                      borderRadius: BorderRadius.circular(8),
                      image: cat.image.isNotEmpty
                          ? DecorationImage(image: NetworkImage(cat.image), fit: BoxFit.cover)
                          : null,
                    ),
                    child: cat.image.isEmpty ? Icon(Icons.category, color: context.colors.border) : null,
                  ),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Order: ${cat.order}', style: TextStyle(fontSize: 12, color: context.colors.textHint)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: cat.isActive,
                        activeThumbColor: context.colors.primary,
                        onChanged: (val) async {
                          await AdminCategoryService().updateCategory(cat.id, {'isActive': val});
                        },
                      ),
                      // Edit button
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: context.colors.primary),
                        onPressed: () => _showEditCategorySheet(context, cat),
                        tooltip: 'Edit',
                      ),
                      // Delete button
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete Category'),
                              content: Text('Are you sure you want to delete ${cat.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: Text('Delete', style: TextStyle(color: context.colors.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await AdminCategoryService().deleteCategory(cat.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Unified Add / Edit Category Sheet ─────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? existingCategory;
  const _CategoryFormSheet({this.existingCategory});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _orderController;

  File? _imageFile;
  bool _isLoading = false;

  bool get _isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCategory?.name ?? '');
    _orderController = TextEditingController(text: widget.existingCategory?.order.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/${const Uuid().v4()}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 60,
        minWidth: 400,
        minHeight: 400,
      );

      setState(() {
        _imageFile = compressedFile != null ? File(compressedFile.path) : file;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final order = int.tryParse(_orderController.text.trim()) ?? 0;

      if (_isEditing) {
        // Edit existing category
        final updates = <String, dynamic>{
          'name': name,
          'order': order,
        };
        if (_imageFile != null) {
          // Upload new image and update URL
          final imageUrl = await AdminCategoryService().uploadCategoryImage(_imageFile!);
          updates['image'] = imageUrl;
        }
        await AdminCategoryService().updateCategory(widget.existingCategory!.id, updates);
      } else {
        // Add new category
        final cat = CategoryModel(
          id: name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), ''),
          name: name,
          image: '',
          order: order,
          isActive: true,
        );
        await AdminCategoryService().addCategory(cat, _imageFile);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Category updated!' : 'Category added!')),
        );
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
    final existingImageUrl = widget.existingCategory?.image ?? '';

    return Container(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Category' : 'Add Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.border),
                        image: _imageFile != null
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : (existingImageUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(existingImageUrl), fit: BoxFit.cover)
                                : null),
                      ),
                      child: (_imageFile == null && existingImageUrl.isEmpty)
                          ? Icon(Icons.add_a_photo, color: context.colors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap to ${existingImageUrl.isNotEmpty || _imageFile != null ? "change" : "add"} image',
                style: TextStyle(fontSize: 12, color: context.colors.textHint),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nameController,
              label: 'Category Name (e.g. Pens)',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _orderController,
              label: 'Sort Order (0, 1, 2...)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isEditing ? 'Save Changes' : 'Save Category',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
