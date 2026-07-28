import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/categories_provider.dart';
import '../widgets/product_card.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class CatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  int _selectedCategory = -1;
  String _sortBy = 'none'; // 'none', 'price_low', 'price_high'
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          'Product Catalog',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (baseCategories) {
          final categories = [
            CategoryModel(id: 'all', name: 'All', image: '', order: -1, isActive: true),
            ...baseCategories,
          ];
          
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          if (_selectedCategory == -1) {
            if (widget.initialCategoryId != null) {
              _selectedCategory = categories.indexWhere((c) => c.id == widget.initialCategoryId);
              if (_selectedCategory == -1) _selectedCategory = 0;
            } else {
              _selectedCategory = 0;
            }
          }

          final selectedCategoryId = categories[_selectedCategory].id;
          final productsAsync = _selectedCategory == 0 
              ? ref.watch(getNewArrivalsProvider(limit: 50))
              : ref.watch(getProductsByCategoryProvider(selectedCategoryId));

          return Column(
        children: [
          // Search + Filter Bar
          Container(
            color: context.colors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search SKU, Product Name...',
                        hintStyle: TextStyle(
                            color: context.colors.textHint, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: context.colors.textHint, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            ListTile(
                              title: const Text('Default'),
                              onTap: () {
                                setState(() => _sortBy = 'none');
                                Navigator.pop(ctx);
                              },
                              trailing: _sortBy == 'none' ? Icon(Icons.check, color: context.colors.primary) : null,
                            ),
                            ListTile(
                              title: const Text('Price: Low to High'),
                              onTap: () {
                                setState(() => _sortBy = 'price_low');
                                Navigator.pop(ctx);
                              },
                              trailing: _sortBy == 'price_low' ? Icon(Icons.check, color: context.colors.primary) : null,
                            ),
                            ListTile(
                              title: const Text('Price: High to Low'),
                              onTap: () {
                                setState(() => _sortBy = 'price_high');
                                Navigator.pop(ctx);
                              },
                              trailing: _sortBy == 'price_high' ? Icon(Icons.check, color: context.colors.primary) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune_rounded,
                        color: context.colors.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Category filter chips
          Container(
            color: context.colors.surface,
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final bool selected = _selectedCategory == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? context.colors.primary : context.colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? context.colors.primary : context.colors.border,
                        ),
                      ),
                      child: Text(
                        categories[i].name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // Product grid — 2 columns, matching home screen layout
          Expanded(
            child: productsAsync.when(
              data: (products) {
                // Sort and Search
                var filteredProducts = List<ProductModel>.from(products);
                
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  filteredProducts = filteredProducts.where((p) => p.name.toLowerCase().contains(query)).toList();
                }

                if (_sortBy == 'price_low') {
                  filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                } else if (_sortBy == 'price_high') {
                  filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                }

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: context.colors.border),
                        const SizedBox(height: 16),
                        Text('No products found', style: TextStyle(fontSize: 16, color: context.colors.textSecondary)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, i) {
                    return ProductCard(product: filteredProducts[i]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      );
    },
    ),
    );
  }
}
