import 'dart:ui';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../models/ad_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/ads_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/ad_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class CatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCategory = -1;
  String _sortBy = 'none';
  final _searchController = TextEditingController();
  final _rightScrollController = ScrollController();
  late AnimationController _fadeController;

  /// Tracks which ad IDs have already had impressions logged this session.
  final Set<String> _loggedImpressions = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rightScrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _selectCategory(int index) {
    if (_selectedCategory == index) return;
    _fadeController.reverse().then((_) {
      setState(() => _selectedCategory = index);
      _rightScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final adsAsync = ref.watch(activeAdsProvider);
    final activeAds = adsAsync.when(
      data: (ads) => ads,
      loading: () => <AdModel>[],
      error: (_, _) => <AdModel>[],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (baseCategories) {
          final categories = [
            CategoryModel(
                id: 'all', name: 'All', image: '', order: -1, isActive: true),
            ...baseCategories,
          ];

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          if (_selectedCategory == -1) {
            if (widget.initialCategoryId != null) {
              _selectedCategory = categories
                  .indexWhere((c) => c.id == widget.initialCategoryId);
              if (_selectedCategory == -1) _selectedCategory = 0;
            } else {
              _selectedCategory = 0;
            }
          }
          if (_selectedCategory < 0 ||
              _selectedCategory >= categories.length) {
            _selectedCategory = 0;
          }

          final selectedCategoryId = categories[_selectedCategory].id;
          final productsAsync =
              ref.watch(activeProductsStreamProvider(selectedCategoryId));

          return Column(
            children: [
              // ── Top Search + Filter bar ─────────────────────────────────
              _buildTopBar(context),

              // ── Body: Left sidebar + Right product grid ─────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─ Left Sidebar ─────────────────────────────────────
                    _buildLeftSidebar(context, categories),

                    // ─ Vertical divider ─────────────────────────────────
                    Container(
                      width: 1,
                      color: const Color(0xFFE8EAED),
                    ),

                    // ─ Right product area ────────────────────────────────
                    Expanded(
                      child: productsAsync.when(
                        data: (products) {
                          var filtered = List<ProductModel>.from(products);
                          final q = _searchController.text.toLowerCase();
                          if (q.isNotEmpty) {
                            filtered = filtered
                                .where(
                                    (p) => p.name.toLowerCase().contains(q))
                                .toList();
                          }
                          if (_sortBy == 'price_low') {
                            filtered
                                .sort((a, b) => a.price.compareTo(b.price));
                          } else if (_sortBy == 'price_high') {
                            filtered
                                .sort((a, b) => b.price.compareTo(a.price));
                          }

                          if (filtered.isEmpty) {
                            return _buildEmptyState(context);
                          }

                          return FadeTransition(
                            opacity: _fadeController,
                            child: _BlinkkitProductGrid(
                              products: filtered,
                              ads: activeAds,
                              loggedImpressions: _loggedImpressions,
                              scrollController: _rightScrollController,
                              categoryName:
                                  categories[_selectedCategory].name,
                            ),
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Error: $err')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back / Title
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.arrow_back, color: context.colors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // Search bar
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                    fontSize: 13, color: context.colors.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                      color: context.colors.textHint, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.colors.textHint, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort button
          GestureDetector(
            onTap: () => _showSortSheet(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sortBy != 'none'
                    ? context.colors.primary
                    : context.colors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sort_rounded,
                color:
                    _sortBy != 'none' ? Colors.white : context.colors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(
      BuildContext context, List<CategoryModel> categories) {
    return Container(
      width: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE8EAED), width: 1),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == i;

          return GestureDetector(
            onTap: () => _selectCategory(i),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // Selected background highlight
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.08),
                        border: Border(
                          left: BorderSide(
                            color: context.colors.primary,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category image / icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: context.colors.primary.withValues(alpha: 0.3), width: 1.5)
                              : Border.all(color: Colors.transparent, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: i == 0
                            ? Icon(
                                Icons.grid_view_rounded,
                                size: 20,
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.textSecondary,
                              )
                            : cat.image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: cat.image,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 100,
                                    placeholder: (_, __) => const SizedBox(),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.category_rounded,
                                      size: 20,
                                      color: isSelected
                                          ? context.colors.primary
                                          : context.colors.textSecondary,
                                    ),
                                  )
                                : Icon(
                                    Icons.category_rounded,
                                    size: 20,
                                    color: isSelected
                                        ? context.colors.primary
                                        : context.colors.textSecondary,
                                  ),
                      ),
                      const SizedBox(height: 6),

                      // Label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: context.colors.border),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
                fontSize: 16, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sort By',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _sortTile(ctx, 'Default', 'none'),
            _sortTile(ctx, 'Price: Low to High', 'price_low'),
            _sortTile(ctx, 'Price: High to Low', 'price_high'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, String label, String value) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(ctx);
      },
      trailing: _sortBy == value
          ? Icon(Icons.check_circle_rounded,
              color: context.colors.primary)
          : null,
    );
  }
}

// ── Product Grid with Blinkit-style layout ──────────────────────────────────

class _BlinkkitProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final List<AdModel> ads;
  final Set<String> loggedImpressions;
  final ScrollController scrollController;
  final String categoryName;

  const _BlinkkitProductGrid({
    required this.products,
    required this.ads,
    required this.loggedImpressions,
    required this.scrollController,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Build combined items with occasional ad injection
    final List<dynamic> combinedItems = [];
    if (ads.isEmpty) {
      combinedItems.addAll(products);
    } else {
      final freq = ads.first.placementFrequency.clamp(4, 100);
      int adRotationIndex = 0;
      for (int i = 0; i < products.length; i++) {
        combinedItems.add(products[i]);
        if ((i + 1) % freq == 0) {
          combinedItems.add(ads[adRotationIndex % ads.length]);
          adRotationIndex++;
        }
      }
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Header strip
        SliverToBoxAdapter(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: const Color(0xFFF5F6FA),
            child: Row(
              children: [
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.length} items',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Product Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 100),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = combinedItems[index];
                if (item is ProductModel) {
                  return ProductCard(product: item);
                } else if (item is AdModel) {
                  return AdCard(
                    ad: item,
                    loggedImpressions: loggedImpressions,
                  );
                }
                return const SizedBox.shrink();
              },
              childCount: combinedItems.length,
            ),
          ),
        ),
      ],
    );
  }
}
