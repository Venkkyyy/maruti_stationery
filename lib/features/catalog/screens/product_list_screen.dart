import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../models/ad_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/ads_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/ad_card.dart';

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

  /// Tracks which ad IDs have already had impressions logged this session.
  final Set<String> _loggedImpressions = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final adsAsync = ref.watch(activeAdsProvider);
    // Resolve active ad list (empty list if loading/error — feed renders normally)
    final activeAds = adsAsync.when(
      data: (ads) => ads,
      loading: () => <AdModel>[],
      error: (_, __) => <AdModel>[],
    );

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
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
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

              // Product grid with injected ad cards
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    var filteredProducts = List<ProductModel>.from(products);

                    final query = _searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      filteredProducts = filteredProducts
                          .where((p) => p.name.toLowerCase().contains(query))
                          .toList();
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
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: context.colors.border),
                            const SizedBox(height: 16),
                            Text('No products found',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: context.colors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return _ProductFeedWithAds(
                      products: filteredProducts,
                      ads: activeAds,
                      loggedImpressions: _loggedImpressions,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error: $err')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Feed builder: products + injected ad cards ──────────────────────────────

/// Builds a custom scroll view that interleaves ad cards between product rows.
///
/// Strategy:
/// - The grid has 2 columns.
/// - An ad is injected after every [ad.placementFrequency] products.
/// - Multiple active ads rotate: ad index = (injection index) % ads.length.
/// - If no ads are active, this renders identically to the original GridView.
class _ProductFeedWithAds extends StatelessWidget {
  final List<ProductModel> products;
  final List<AdModel> ads;
  final Set<String> loggedImpressions;

  const _ProductFeedWithAds({
    required this.products,
    required this.ads,
    required this.loggedImpressions,
  });

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      // No ads — original 2-column grid, unchanged
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemCount: products.length,
        itemBuilder: (context, i) => ProductCard(product: products[i]),
      );
    }

    // Build a list of slivers: grid rows + ad cards
    final slivers = <Widget>[];
    const cols = 2;
    // Use the first ad's placement frequency; fallback to 8
    final freq = ads.first.placementFrequency.clamp(2, 100);
    // freq is product count between ads; convert to row count
    final rowsPerAd = (freq / cols).ceil();

    int productIndex = 0;
    int adRotationIndex = 0;

    while (productIndex < products.length) {
      // How many product rows before the next ad insertion
      final endProductIndex =
          (productIndex + rowsPerAd * cols).clamp(0, products.length);
      final chunk = products.sublist(productIndex, endProductIndex);

      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            productIndex == 0 ? 16 : 0,
            16,
            0,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => ProductCard(product: chunk[i]),
              childCount: chunk.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
          ),
        ),
      );

      productIndex = endProductIndex;

      // Insert ad if there are more products following
      if (productIndex < products.length) {
        final ad = ads[adRotationIndex % ads.length];
        adRotationIndex++;
        slivers.add(
          SliverToBoxAdapter(
            child: AdCard(
              ad: ad,
              loggedImpressions: loggedImpressions,
            ),
          ),
        );
      }
    }

    // Bottom padding sliver
    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 16)));

    return CustomScrollView(slivers: slivers);
  }
}
