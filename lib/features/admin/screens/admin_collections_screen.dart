import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_collection_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/storefront_provider.dart';

class AdminCollectionsScreen extends ConsumerStatefulWidget {
  const AdminCollectionsScreen({super.key});

  @override
  ConsumerState<AdminCollectionsScreen> createState() => _AdminCollectionsScreenState();
}

class _AdminCollectionsScreenState extends ConsumerState<AdminCollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(productCollectionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Product Collections',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.navyText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Collection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        onPressed: () => _openCollectionForm(context, null),
      ),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_motion_rounded, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'No Collections Yet',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create curated product collections to showcase on storefront sections',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final col = collections[index];
              final isManual = col.type == CollectionType.manual;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isManual ? AppColors.primary : AppColors.royalBlue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isManual ? Icons.format_list_bulleted_rounded : Icons.auto_awesome_rounded,
                      color: isManual ? AppColors.primary : AppColors.royalBlue,
                    ),
                  ),
                  title: Text(
                    col.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (col.description.isNotEmpty)
                        Text(
                          col.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isManual ? AppColors.primaryLight : const Color(0xFFEBF3FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isManual ? 'MANUAL (${col.productIds.length} items)' : 'AUTOMATIC RULE',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isManual ? AppColors.primaryDark : AppColors.royalBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            col.isEnabled ? 'Active' : 'Disabled',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: col.isEnabled ? const Color(0xFF16A34A) : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _openCollectionForm(context, col),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, col),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openCollectionForm(BuildContext context, ProductCollectionModel? initial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _CollectionFormSheet(collection: initial),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductCollectionModel col) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${col.name}"?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this product collection? Any storefront section linking to it will safely revert to default catalog view.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(storefrontServiceProvider).deleteCollection(col.id);
    }
  }
}

class _CollectionFormSheet extends ConsumerStatefulWidget {
  final ProductCollectionModel? collection;
  const _CollectionFormSheet({this.collection});

  @override
  ConsumerState<_CollectionFormSheet> createState() => _CollectionFormSheetState();
}

class _CollectionFormSheetState extends ConsumerState<_CollectionFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = CollectionType.manual;
  String _autoRule = CollectionRuleType.trending;
  List<String> _selectedProductIds = [];
  bool _isEnabled = true;
  int _maxProducts = 15;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      final c = widget.collection!;
      _nameCtrl.text = c.name;
      _descCtrl.text = c.description;
      _type = c.type;
      _selectedProductIds = List.from(c.productIds);
      _autoRule = (c.rules['ruleType'] ?? CollectionRuleType.trending).toString();
      _isEnabled = c.isEnabled;
      _maxProducts = c.maxProducts;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProductsAsync = ref.watch(activeProductsStreamProvider('all'));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.collection != null ? 'Edit Collection' : 'Create Product Collection',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navyText),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Collection Name (e.g. Back to School Essentials)',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Subtitle / Description (Optional)',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              Text('Collection Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Manual Selection')),
                      selected: _type == CollectionType.manual,
                      onSelected: (val) => setState(() => _type = CollectionType.manual),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Automatic Rule')),
                      selected: _type == CollectionType.automatic,
                      onSelected: (val) => setState(() => _type = CollectionType.automatic),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_type == CollectionType.automatic) ...[
                Text('Automatic Evaluation Rule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _autoRule,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: CollectionRuleType.trending, child: Text('🔥 Trending (Most sales & view activity)')),
                    DropdownMenuItem(value: CollectionRuleType.bestSellers, child: Text('🏆 Best Sellers (Highest total sold units)')),
                    DropdownMenuItem(value: CollectionRuleType.newArrivals, child: Text('✨ New Arrivals (Recently added products)')),
                    DropdownMenuItem(value: CollectionRuleType.topRated, child: Text('⭐ Top Rated (Rating >= 4.0 stars)')),
                    DropdownMenuItem(value: CollectionRuleType.onSale, child: Text('🏷 Clearance & On Sale (Discounted items)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _autoRule = val);
                  },
                ),
              ] else ...[
                Text(
                  'Select Products (${_selectedProductIds.length} Selected)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),

                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search products by name or brand...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),

                allProductsAsync.when(
                  data: (products) {
                    final filtered = products.where((p) {
                      if (_searchQuery.isEmpty) return true;
                      return p.name.toLowerCase().contains(_searchQuery) ||
                          p.brand.toLowerCase().contains(_searchQuery);
                    }).take(15).toList();

                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final prod = filtered[i];
                          final isSelected = _selectedProductIds.contains(prod.id);

                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            title: Text(prod.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(AppFormatters.formatPrice(prod.price)),
                            secondary: prod.images.isNotEmpty
                                ? SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CachedNetworkImage(imageUrl: prod.images.first, fit: BoxFit.cover),
                                  )
                                : null,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedProductIds.add(prod.id);
                                } else {
                                  _selectedProductIds.remove(prod.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],

              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Active & Published', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                value: _isEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _isEnabled = val),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (_nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a collection name.')));
                      return;
                    }

                    final col = ProductCollectionModel(
                      id: widget.collection?.id ?? '',
                      name: _nameCtrl.text.trim(),
                      description: _descCtrl.text.trim(),
                      type: _type,
                      rules: {'ruleType': _autoRule},
                      productIds: _selectedProductIds,
                      maxProducts: _maxProducts,
                      isEnabled: _isEnabled,
                      createdAt: widget.collection?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await ref.read(storefrontServiceProvider).saveCollection(col);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(
                    widget.collection != null ? 'Update Collection' : 'Create Collection',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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
