import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/storefront_section_model.dart';
import '../../../models/category_model.dart';
import '../../../models/product_collection_model.dart';
import '../../../providers/storefront_provider.dart';

class AdminHomeLayoutScreen extends ConsumerStatefulWidget {
  const AdminHomeLayoutScreen({super.key});

  @override
  ConsumerState<AdminHomeLayoutScreen> createState() => _AdminHomeLayoutScreenState();
}

class _AdminHomeLayoutScreenState extends ConsumerState<AdminHomeLayoutScreen> {
  List<StorefrontSectionModel> _sections = [];
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _hasUnsavedChanges = false;
  List<CategoryModel> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('categories').orderBy('name').get();
      if (mounted) {
        setState(() {
          _availableCategories = snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
        });
      }
    } catch (_) {}
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= _sections.length) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _sections.removeAt(oldIndex);
      final targetIndex = newIndex.clamp(0, _sections.length);
      _sections.insert(targetIndex, item);
      _hasUnsavedChanges = true;
    });
  }

  void _toggleSection(int index, bool val) {
    setState(() {
      _sections[index] = _sections[index].copyWith(isEnabled: val);
      _hasUnsavedChanges = true;
    });
  }

  void _duplicateSection(int index) {
    final original = _sections[index];
    final copy = original.copyWith(
      id: 'sec_${const Uuid().v4().substring(0, 8)}',
      title: '${original.title} (Copy)',
      order: index + 1,
    );
    setState(() {
      _sections.insert(index + 1, copy);
      _hasUnsavedChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated "${original.title}"')),
    );
  }

  void _deleteSection(int index) {
    final deleted = _sections[index];
    setState(() {
      _sections.removeAt(index);
      _hasUnsavedChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${deleted.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.amber,
          onPressed: () {
            setState(() {
              _sections.insert(index, deleted);
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    try {
      await ref.read(storefrontServiceProvider).saveDraft(
        pageId: 'home',
        sections: _sections,
        userId: userId,
      );
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Draft saved successfully! Staged for preview & release.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishToCustomers() async {
    final validationErrors = ref.read(storefrontServiceProvider).validateSections(_sections);
    if (validationErrors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Validation Issues Found', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: validationErrors.map((err) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(err, style: GoogleFonts.poppins(fontSize: 12))),
                ],
              ),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final summaryCtrl = TextEditingController(text: 'Updated home sections and layout');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Publish to Live Customers?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will instantly publish your staged draft to all Maruti Stationery customers without requiring an app store update.'),
            const SizedBox(height: 14),
            TextField(
              controller: summaryCtrl,
              decoration: InputDecoration(
                labelText: 'Release Notes / Change Summary',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isPublishing = true);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
      try {
        await _saveDraft();
        await ref.read(storefrontServiceProvider).publishDraft(
          pageId: 'home',
          userId: userId,
          changeSummary: summaryCtrl.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 Published live! Customers receive updated experience immediately.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publishing error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(draftStorefrontStreamProvider('home'));
    final collections = ref.watch(productCollectionsStreamProvider).value ?? [];

    if (!_isInitialized && draftAsync.hasValue) {
      _sections = List.from(draftAsync.value!.sections);
      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Home Screen Builder',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.navyText),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Live Device Preview',
            icon: const Icon(Icons.phone_iphone_rounded, color: AppColors.royalBlue),
            onPressed: () => context.push('/admin/storefront/preview'),
          ),
          IconButton(
            tooltip: 'Version History & Rollback',
            icon: const Icon(Icons.history_rounded, color: AppColors.navyText),
            onPressed: () => context.push('/admin/storefront/history'),
          ),
          if (_hasUnsavedChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveDraft,
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text('Save Draft', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.royalBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push('/admin/storefront/preview'),
                  icon: const Icon(Icons.visibility_rounded, color: AppColors.royalBlue),
                  label: Text('Preview Draft', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.royalBlue)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isPublishing ? null : _publishToCustomers,
                  icon: _isPublishing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                  label: Text('Publish Live', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navyText,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Section', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
        onPressed: () => _openSectionForm(null, collections),
      ),
      body: draftAsync.when(
        data: (_) {
          if (_sections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.layers_clear_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No sections configured', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _openSectionForm(null, collections),
                    child: const Text('Add First Section'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _hasUnsavedChanges ? const Color(0xFFFEF3C7) : const Color(0xFFEBF3FE),
                child: Row(
                  children: [
                    Icon(
                      _hasUnsavedChanges ? Icons.info_outline : Icons.check_circle_outline,
                      size: 16,
                      color: _hasUnsavedChanges ? const Color(0xFFB45309) : AppColors.royalBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hasUnsavedChanges
                            ? 'Unsaved changes in draft. Drag to reorder, then save or publish.'
                            : 'Draft canvas in sync with staged release.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _hasUnsavedChanges ? const Color(0xFFB45309) : AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: _sections.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final s = _sections[index];
                    return _buildSectionCard(s, index, collections);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error loading draft: $e')),
      ),
    );
  }

  Widget _buildSectionCard(StorefrontSectionModel s, int index, List<ProductCollectionModel> collections) {
    return Container(
      key: ValueKey(s.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.isEnabled ? AppColors.border : Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: s.isEnabled ? AppColors.royalBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: s.isEnabled ? AppColors.royalBlue : Colors.grey,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.title.isNotEmpty ? s.title : StorefrontSectionType.getLabel(s.type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: s.isEnabled ? AppColors.navyText : Colors.grey,
                ),
              ),
            ),
            Switch(
              value: s.isEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) => _toggleSection(index, val),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                StorefrontSectionType.getLabel(s.type).toUpperCase(),
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.layoutVariant.replaceAll('_', ' '),
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _openSectionForm(s, collections, editIndex: index),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (val) {
                if (val == 'duplicate') _duplicateSection(index);
                if (val == 'delete') _deleteSection(index);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, size: 16), SizedBox(width: 8), Text('Duplicate')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
            const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _openSectionForm(StorefrontSectionModel? initial, List<ProductCollectionModel> collections, {int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _SectionFormSheet(
        section: initial,
        categories: _availableCategories,
        collections: collections,
        onSave: (saved) {
          setState(() {
            if (editIndex != null) {
              _sections[editIndex] = saved;
            } else {
              _sections.add(saved.copyWith(order: _sections.length));
            }
            _hasUnsavedChanges = true;
          });
          Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

class _SectionFormSheet extends StatefulWidget {
  final StorefrontSectionModel? section;
  final List<CategoryModel> categories;
  final List<ProductCollectionModel> collections;
  final ValueChanged<StorefrontSectionModel> onSave;

  const _SectionFormSheet({
    this.section,
    required this.categories,
    required this.collections,
    required this.onSave,
  });

  @override
  State<_SectionFormSheet> createState() => _SectionFormSheetState();
}

class _SectionFormSheetState extends State<_SectionFormSheet> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  String _type = StorefrontSectionType.customProducts;
  String _layoutVariant = StorefrontLayoutVariant.carouselStandard;
  String? _collectionId;
  String? _categoryId;
  int _limit = 8;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      final s = widget.section!;
      _titleCtrl.text = s.title;
      _subtitleCtrl.text = s.subtitle;
      _type = s.type;
      _layoutVariant = s.layoutVariant;
      _collectionId = s.collectionId;
      _categoryId = s.categoryId;
      _limit = s.limit;
      _isEnabled = s.isEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.section != null ? 'Edit Section' : 'Add New Section',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navyText),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Section Title (e.g. 🔥 Best Sellers)',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _subtitleCtrl,
                decoration: InputDecoration(
                  labelText: 'Subtitle (Optional)',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              Text('Section Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: StorefrontSectionType.allTypes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(StorefrontSectionType.getLabel(t)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 14),

              Text('Layout Variant', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _layoutVariant,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: StorefrontLayoutVariant.carouselStandard, child: Text('Horizontal Carousel (Standard)')),
                  DropdownMenuItem(value: StorefrontLayoutVariant.carouselCompact, child: Text('Horizontal Carousel (Compact)')),
                  DropdownMenuItem(value: StorefrontLayoutVariant.grid2Col, child: Text('2-Column Grid')),
                  DropdownMenuItem(value: StorefrontLayoutVariant.grid3Col, child: Text('3-Column Grid')),
                  DropdownMenuItem(value: StorefrontLayoutVariant.categoryPills, child: Text('Category Pills')),
                  DropdownMenuItem(value: StorefrontLayoutVariant.bannerCarousel, child: Text('Banner Carousel')),
                  DropdownMenuItem(value: StorefrontLayoutVariant.bannerFull, child: Text('Full-Width Banner')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _layoutVariant = val);
                },
              ),
              const SizedBox(height: 14),

              if (widget.collections.isNotEmpty) ...[
                Text('Linked Product Collection (Optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: widget.collections.any((c) => c.id == _collectionId) ? _collectionId : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (Use Default Query)')),
                    ...widget.collections.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (val) => setState(() => _collectionId = val),
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Text('Item Limit: $_limit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _limit.toDouble(),
                      min: 4,
                      max: 20,
                      divisions: 8,
                      label: '$_limit',
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _limit = val.toInt()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final s = StorefrontSectionModel(
                      id: widget.section?.id ?? 'sec_${const Uuid().v4().substring(0, 8)}',
                      type: _type,
                      title: _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : StorefrontSectionType.getLabel(_type),
                      subtitle: _subtitleCtrl.text.trim(),
                      layoutVariant: _layoutVariant,
                      collectionId: _collectionId,
                      categoryId: _categoryId,
                      limit: _limit,
                      isEnabled: _isEnabled,
                      order: widget.section?.order ?? 0,
                    );
                    widget.onSave(s);
                  },
                  child: Text(
                    widget.section != null ? 'Update Section' : 'Add to Draft',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
