import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/home_section_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/home_layout_provider.dart';

class AdminHomeLayoutScreen extends ConsumerStatefulWidget {
  const AdminHomeLayoutScreen({super.key});

  @override
  ConsumerState<AdminHomeLayoutScreen> createState() => _AdminHomeLayoutScreenState();
}

class _AdminHomeLayoutScreenState extends ConsumerState<AdminHomeLayoutScreen> {
  List<HomeSectionModel> _sections = [];
  bool _isInitialized = false;
  bool _isSaving = false;
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

  Future<void> _saveLayout() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(homeLayoutServiceProvider).saveLayout(_sections);
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Home screen layout updated and live for customers!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save layout: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Reset to Default Layout?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('This will restore Maruti Stationery\'s standard home screen section order. Any custom sections will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _sections = List.from(HomeSectionModel.defaultSections);
        _hasUnsavedChanges = true;
      });
      await _saveLayout();
    }
  }

  void _openAddSectionDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String sectionType = 'custom_products'; // 'custom_products', 'new_arrivals', 'trending'
    String? selectedCategoryId;
    String displayStyle = 'horizontal'; // 'horizontal', 'grid'
    int limit = 8;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New Section',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyText),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Section Title (e.g. Back to School Specials)',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: InputDecoration(
                        labelText: 'Subtitle (Optional, e.g. Handpicked for students)',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Section Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: sectionType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'custom_products', child: Text('Custom Product Category / Collection')),
                        DropdownMenuItem(value: 'new_arrivals', child: Text('Newly Added Products (New Arrivals)')),
                        DropdownMenuItem(value: 'trending', child: Text('Trending / Best Sellers')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => sectionType = val);
                      },
                    ),
                    if (sectionType == 'custom_products') ...[
                      const SizedBox(height: 14),
                      Text('Filter by Category (Optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: _availableCategories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceWarm,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Products')),
                          ..._availableCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setSheetState(() => selectedCategoryId = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Display Style', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: displayStyle,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceWarm,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'horizontal', child: Text('Horizontal Scroll')),
                                  DropdownMenuItem(value: 'grid', child: Text('2-Column Grid')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => displayStyle = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Max Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: limit,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceWarm,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                items: [4, 6, 8, 10, 12, 16].map((n) => DropdownMenuItem(value: n, child: Text('$n items'))).toList(),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => limit = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a section title')),
                            );
                            return;
                          }

                          String? categoryName;
                          if (selectedCategoryId != null) {
                            final match = _availableCategories.where((c) => c.id == selectedCategoryId);
                            if (match.isNotEmpty) categoryName = match.first.name;
                          }

                          final newSection = HomeSectionModel(
                            id: 'sec_custom_${const Uuid().v4().substring(0, 8)}',
                            type: sectionType,
                            title: title,
                            subtitle: subtitleController.text.trim(),
                            isEnabled: true,
                            displayStyle: displayStyle,
                            categoryId: selectedCategoryId,
                            categoryName: categoryName,
                            limit: limit,
                            order: _sections.length,
                          );

                          setState(() {
                            _sections.add(newSection);
                            _hasUnsavedChanges = true;
                          });

                          Navigator.pop(sheetContext);
                        },
                        child: Text('Add Section to Home Screen', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEditSectionDialog(int index) {
    final s = _sections[index];
    final titleController = TextEditingController(text: s.title);
    final subtitleController = TextEditingController(text: s.subtitle);
    String? selectedCategoryId = s.categoryId;
    String displayStyle = s.displayStyle;
    int limit = s.limit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isProductSection = s.type == 'trending' || s.type == 'new_arrivals' || s.type == 'custom_products';

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configure Section',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyText),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Section Display Title',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: InputDecoration(
                        labelText: 'Subtitle (Optional)',
                        labelStyle: GoogleFonts.poppins(fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    if (s.type == 'custom_products') ...[
                      const SizedBox(height: 14),
                      Text('Category Filter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: _availableCategories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceWarm,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Products')),
                          ..._availableCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setSheetState(() => selectedCategoryId = val);
                        },
                      ),
                    ],
                    if (isProductSection) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Display Style', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: (displayStyle == 'horizontal' || displayStyle == 'grid') ? displayStyle : 'grid',
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surfaceWarm,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'horizontal', child: Text('Horizontal Scroll')),
                                    DropdownMenuItem(value: 'grid', child: Text('2-Column Grid')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => displayStyle = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Max Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: limit,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surfaceWarm,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  items: [4, 6, 8, 10, 12, 16].map((n) => DropdownMenuItem(value: n, child: Text('$n items'))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setSheetState(() => limit = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          String? categoryName;
                          if (selectedCategoryId != null) {
                            final match = _availableCategories.where((c) => c.id == selectedCategoryId);
                            if (match.isNotEmpty) categoryName = match.first.name;
                          }

                          setState(() {
                            _sections[index] = _sections[index].copyWith(
                              title: title,
                              subtitle: subtitleController.text.trim(),
                              categoryId: selectedCategoryId,
                              categoryName: categoryName,
                              displayStyle: displayStyle,
                              limit: limit,
                            );
                            _hasUnsavedChanges = true;
                          });

                          Navigator.pop(sheetContext);
                        },
                        child: Text('Save Section Configuration', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'categories':
        return Icons.category_rounded;
      case 'banners':
        return Icons.view_carousel_rounded;
      case 'use_case':
        return Icons.auto_awesome_mosaic_rounded;
      case 'trending':
        return Icons.trending_up_rounded;
      case 'new_arrivals':
        return Icons.new_releases_rounded;
      case 'buy_again':
        return Icons.repeat_rounded;
      case 'ads':
        return Icons.smart_display_rounded;
      case 'custom_products':
      default:
        return Icons.storefront_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'categories':
        return const Color(0xFFF59E0B);
      case 'banners':
        return AppColors.royalBlue;
      case 'use_case':
        return const Color(0xFF8B5CF6);
      case 'trending':
        return AppColors.primary;
      case 'new_arrivals':
        return const Color(0xFF10B981);
      case 'buy_again':
        return const Color(0xFF0284C7);
      case 'ads':
        return const Color(0xFFE11D48);
      case 'custom_products':
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncLayout = ref.watch(homeLayoutStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Customer Home Layout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () {
            if (_hasUnsavedChanges) {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Discard Unsaved Changes?'),
                  content: const Text('You have reordered or modified sections without saving.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Stay')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(c);
                        if (context.canPop()) context.pop();
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/dashboard');
              }
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Reset to Default',
            icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textSecondary),
            onPressed: _resetToDefault,
          ),
          IconButton(
            tooltip: 'Add Section',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.royalBlue, size: 24),
            onPressed: _openAddSectionDialog,
          ),
        ],
      ),
      bottomNavigationBar: _hasUnsavedChanges
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: const [
                  BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unsaved Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navyText)),
                          Text('Changes will apply to live customers', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _saveLayout,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Save & Publish', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: asyncLayout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading layout: $err')),
        data: (savedSections) {
          if (!_isInitialized || !_hasUnsavedChanges) {
            _sections = List.from(savedSections);
            _isInitialized = true;
          }
          if (_sections.isEmpty) {
            _sections = List.from(HomeSectionModel.defaultSections);
          }

          return Column(
            children: [
              // Instruction Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator_rounded, color: AppColors.royalBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Drag handles ☰ to re-order. Toggle switches to show/hide. Tap edit ✏️ to customize.',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.navyText, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: _sections.length,
                  buildDefaultDragHandles: false,
                  onReorder: _onReorder,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 6,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final s = _sections[index];
                    final color = _getColorForType(s.type);
                    final icon = _getIconForType(s.type);
                    final isCustom = s.type == 'custom_products';

                    return Container(
                      key: ValueKey('sec_${s.id}_$index'),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: s.isEnabled ? AppColors.surface : AppColors.surfaceWarm.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: s.isEnabled ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
                        ),
                        boxShadow: s.isEnabled
                            ? const [
                                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                              ]
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.drag_indicator_rounded, color: AppColors.textSecondary, size: 20),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Type icon
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: s.isEnabled ? 0.12 : 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: s.isEnabled ? color : AppColors.textSecondary, size: 20),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: s.isEnabled ? AppColors.navyText : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (s.displayStyle == 'grid')
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWarm,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Grid', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            s.subtitle.isNotEmpty
                                ? s.subtitle
                                : (s.categoryName != null ? 'Category: ${s.categoryName}' : 'Position ${index + 1}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.royalBlue),
                              tooltip: 'Edit Section',
                              onPressed: () => _openEditSectionDialog(index),
                            ),
                            // Delete if custom section
                            if (isCustom)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                tooltip: 'Delete Section',
                                onPressed: () => _deleteSection(index),
                              ),
                            // Toggle
                            Switch(
                              value: s.isEnabled,
                              activeThumbColor: AppColors.royalBlue,
                              onChanged: (val) => _toggleSection(index, val),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
