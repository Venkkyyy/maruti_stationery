import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../../models/brand_model.dart';
import '../../../services/admin_brand_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  void _showAddBrandSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BrandFormSheet(),
    );
  }

  void _showEditBrandSheet(BuildContext context, BrandModel brand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BrandFormSheet(existingBrand: brand),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Manage Brands'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        onPressed: () => _showAddBrandSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('brands').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No brands found.'));
          }

          final brands = snapshot.data!.docs
              .map((doc) => BrandModel.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: brands.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: ListTile(
                  onTap: () => _showEditBrandSheet(context, brand),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceGrey,
                      borderRadius: BorderRadius.circular(8),
                      image: brand.logoUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(brand.logoUrl), fit: BoxFit.contain)
                          : null,
                    ),
                    child: brand.logoUrl.isEmpty ? Icon(Icons.branding_watermark, color: context.colors.border) : null,
                  ),
                  title: Text(brand.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: brand.isActive,
                        activeThumbColor: context.colors.primary,
                        onChanged: (val) async {
                          final updated = BrandModel(
                            id: brand.id,
                            name: brand.name,
                            logoUrl: brand.logoUrl,
                            isActive: val,
                            createdAt: brand.createdAt,
                          );
                          await AdminBrandService().updateBrand(updated);
                        },
                      ),
                      // Edit button
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: context.colors.primary),
                        onPressed: () => _showEditBrandSheet(context, brand),
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
                              title: const Text('Delete Brand'),
                              content: Text('Are you sure you want to delete ${brand.name}?'),
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
                            await AdminBrandService().deleteBrand(brand.id);
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

// ── Unified Add / Edit Brand Sheet ─────────────────────────────────────

class _BrandFormSheet extends StatefulWidget {
  final BrandModel? existingBrand;
  const _BrandFormSheet({this.existingBrand});

  @override
  State<_BrandFormSheet> createState() => _BrandFormSheetState();
}

class _BrandFormSheetState extends State<_BrandFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  File? _imageFile;
  bool _removeLogo = false;
  bool _isLoading = false;

  bool get _isEditing => widget.existingBrand != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingBrand?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
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
        _removeLogo = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();

      if (_isEditing) {
        String logoUrl = _removeLogo ? '' : widget.existingBrand!.logoUrl;
        if (_imageFile != null) {
          logoUrl = await AdminBrandService().uploadBrandImage(_imageFile!);
        }
        
        final updated = BrandModel(
          id: widget.existingBrand!.id,
          name: name,
          logoUrl: logoUrl,
          isActive: widget.existingBrand!.isActive,
          createdAt: widget.existingBrand!.createdAt,
        );
        await AdminBrandService().updateBrand(updated);
      } else {
        String logoUrl = '';
        if (_imageFile != null && !_removeLogo) {
          logoUrl = await AdminBrandService().uploadBrandImage(_imageFile!);
        }
        
        final brand = BrandModel(
          id: name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), ''),
          name: name,
          logoUrl: logoUrl,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await AdminBrandService().addBrand(brand);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Brand updated!' : 'Brand added!')),
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
    final existingImageUrl = widget.existingBrand?.logoUrl ?? '';
    final hasActiveLogo = _imageFile != null || (existingImageUrl.isNotEmpty && !_removeLogo);

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
                  _isEditing ? 'Edit Brand' : 'Add Brand',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 104, height: 104,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _removeLogo ? Colors.red.withValues(alpha: 0.5) : context.colors.border,
                          width: _removeLogo ? 1.5 : 1,
                        ),
                        image: _imageFile != null
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.contain)
                            : (existingImageUrl.isNotEmpty && !_removeLogo
                                ? DecorationImage(image: NetworkImage(existingImageUrl), fit: BoxFit.contain)
                                : null),
                      ),
                      child: !hasActiveLogo
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: context.colors.primary, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Logo',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.primary),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: -2, right: -2,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (hasActiveLogo)
                    Positioned(
                      top: -6, right: -6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_imageFile != null) {
                              _imageFile = null;
                            } else {
                              _removeLogo = true;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.close, size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: _removeLogo
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        const Text(
                          'Logo will be removed upon save. ',
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _removeLogo = false),
                          child: Text(
                            'Undo',
                            style: TextStyle(fontSize: 12, color: context.colors.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    )
                  : (hasActiveLogo
                      ? TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_imageFile != null) {
                                _imageFile = null;
                              } else {
                                _removeLogo = true;
                              }
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: const Text('Remove Logo', style: TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        )
                      : Text(
                          'Tap the box to choose a logo from gallery',
                          style: TextStyle(fontSize: 12, color: context.colors.textHint),
                        )),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Brand Name (e.g. Classmate)',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isEditing ? 'Save Changes' : 'Save Brand',
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
