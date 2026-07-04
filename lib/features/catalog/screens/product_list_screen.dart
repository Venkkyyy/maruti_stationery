import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────

class _MockProduct {
  final String id;
  final String name;
  final String sku;
  final double sellingPrice;
  final double? mrp;
  final int stock;
  final IconData icon;
  final Color bgColor;

  const _MockProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.sellingPrice,
    this.mrp,
    required this.stock,
    required this.icon,
    required this.bgColor,
  });

  bool get isOutOfStock => stock == 0;
  bool get isLowStock => stock > 0 && stock <= 10;
  int? get discountPercent {
    if (mrp == null || mrp! <= sellingPrice) return null;
    return (((mrp! - sellingPrice) / mrp!) * 100).round();
  }
}

const _kProducts = [
  _MockProduct(
    id: '1',
    name: 'Executive Fountain Pen',
    sku: 'PN-8924',
    sellingPrice: 45.00,
    mrp: 63.38,
    stock: 42,
    icon: Icons.edit_rounded,
    bgColor: Color(0xFFF1F3F4),
  ),
  _MockProduct(
    id: '2',
    name: 'Grid Ruled Notebook A5',
    sku: 'NB-1055',
    sellingPrice: 12.50,
    mrp: 14.70,
    stock: 128,
    icon: Icons.auto_stories_rounded,
    bgColor: Color(0xFFF8F9FA),
  ),
  _MockProduct(
    id: '3',
    name: 'Modular Desk Caddy',
    sku: 'DC-002',
    sellingPrice: 24.00,
    mrp: null,
    stock: 4,
    icon: Icons.desk_rounded,
    bgColor: Color(0xFFF8F9FA),
  ),
  _MockProduct(
    id: '4',
    name: 'Binder Clips (Pack of 50)',
    sku: 'BC-50P',
    sellingPrice: 4.50,
    mrp: null,
    stock: 0,
    icon: Icons.attach_file_rounded,
    bgColor: Color(0xFFF1F3F4),
  ),
  _MockProduct(
    id: '5',
    name: 'Parker Sonnet Rollerball',
    sku: 'PK-SN-01',
    sellingPrice: 89.00,
    mrp: 120.00,
    stock: 15,
    icon: Icons.draw_rounded,
    bgColor: Color(0xFFE8F0FE),
  ),
  _MockProduct(
    id: '6',
    name: 'Midnight Ink Bottle 50ml',
    sku: 'INK-MN-50',
    sellingPrice: 12.00,
    mrp: null,
    stock: 8,
    icon: Icons.water_drop_rounded,
    bgColor: Color(0xFFE8F0FE),
  ),
];

const _kCategories = [
  'All Categories',
  'Paper Goods',
  'Writing Tools',
  'Inks',
  'Office',
  'Art',
];

// ── Screen ─────────────────────────────────────────────────────────────────

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _selectedCategory = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        // Removed leading menu icon
        title: Text(
          'Product Catalog',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ),
        actions: [
          // Removed cart icon as it is now in the bottom nav
        ],
      ),
      body: Column(
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
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded,
                      color: context.colors.primary, size: 20),
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
                itemCount: _kCategories.length,
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
                        _kCategories[i],
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _kProducts.length + 1, // +1 for load more button
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == _kProducts.length) {
                  return _LoadMoreButton();
                }
                return _ProductListCard(product: _kProducts[i]);
              },
            ),
          ),
        ],
      ),

      // FAB — Add new product
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ── Product List Card ──────────────────────────────────────────────────────

class _ProductListCard extends StatelessWidget {
  final _MockProduct product;
  const _ProductListCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;

    return GestureDetector(
      onTap: () => context.go('/catalog/product/${product.id}'),
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
                    color: product.isOutOfStock
                        ? Colors.grey.shade200
                        : product.bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  child: product.isOutOfStock
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: Icon(product.icon,
                              size: 38,
                              color: context.colors.primary.withValues(alpha: 0.4)),
                        )
                      : Icon(product.icon,
                          size: 38,
                          color: context.colors.primary.withValues(alpha: 0.6)),
                ),
                // Discount badge
                if (discount != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.only(
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
                if (product.isOutOfStock)
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
                    // SKU + Stock
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'SKU: ${product.sku}',
                            style: TextStyle(
                              color: product.isLowStock
                                  ? context.colors.error
                                  : context.colors.textHint,
                              fontWeight: product.isLowStock
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: product.isOutOfStock
                                ? ' • Stock: 0'
                                : product.isLowStock
                                    ? ' • Low Stock: ${product.stock}'
                                    : ' • Stock: ${product.stock}',
                            style: TextStyle(
                              color: product.isLowStock
                                  ? context.colors.error
                                  : context.colors.textHint,
                              fontWeight: product.isLowStock
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price row
                    Row(
                      children: [
                        Text(
                          '\$${product.sellingPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (product.mrp != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${product.mrp!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: context.colors.textHint, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Load More Button ───────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.colors.border),
          foregroundColor: context.colors.textSecondary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
        child: Text(
          'Load More Products',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}






