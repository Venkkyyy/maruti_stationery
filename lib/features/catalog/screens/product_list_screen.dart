import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/categories_provider.dart';

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

          // Product list
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
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    return _ProductListCard(product: filteredProducts[i]);
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

// ── Product List Card ──────────────────────────────────────────────────────

class _ProductListCard extends StatelessWidget {
  final ProductModel product;
  const _ProductListCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 10;

    return GestureDetector(
      onTap: () => context.push('/catalog/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.grey.shade200
                        : context.colors.surfaceGrey,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  child: product.primaryImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                          child: isOutOfStock 
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]),
                                child: Image.network(product.primaryImage, fit: BoxFit.cover),
                              )
                            : Image.network(product.primaryImage, fit: BoxFit.cover),
                        )
                      : Icon(Icons.image_not_supported_rounded, color: context.colors.textHint),
                ),
                // Discount badge
                if (discount > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Out of stock overlay
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'OUT OF\nSTOCK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Stock status
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12),
                        children: [
                          TextSpan(
                            text: isOutOfStock
                                ? 'Stock: 0'
                                : isLowStock
                                    ? 'Low Stock: ${product.stock}'
                                    : 'Stock: ${product.stock}',
                            style: TextStyle(
                              color: isLowStock || isOutOfStock
                                  ? context.colors.error
                                  : context.colors.textHint,
                              fontWeight: isLowStock || isOutOfStock
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price row
                    Wrap(
                      spacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppFormatters.formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (product.isOnSale)
                          Text(
                            AppFormatters.formatPrice(product.mrp),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: context.colors.textHint, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
