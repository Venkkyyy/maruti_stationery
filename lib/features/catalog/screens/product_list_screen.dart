import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2 — PRODUCT LISTING SCREEN (Exact Reference: Screen 3 "Notebooks")
// ─────────────────────────────────────────────────────────────────────────────

class CatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late String _currentCategoryId;
  String _selectedSubFilter = 'All';
  String _sortBy = 'popularity'; // popularity, price_low, price_high, newest, rating
  String _priceFilter = 'all'; // all, under_100, 100_300, 300_500, above_500
  bool _inStockOnly = false;
  bool _onSaleOnly = false;
  String? _selectedBrand;
  bool _isGridView = true;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentCategoryId = widget.initialCategoryId ?? 'all';
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _currentCategoryId = widget.initialCategoryId ?? 'all';
        _selectedSubFilter = 'All';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedSubFilter = 'All';
      _sortBy = 'popularity';
      _priceFilter = 'all';
      _inStockOnly = false;
      _onSaleOnly = false;
      _selectedBrand = null;
      _searchController.clear();
      _isSearchExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
    final productsAsync = ref.watch(activeProductsStreamProvider(_currentCategoryId));

    // Resolve category name dynamically
    String categoryName = 'Products';
    if (_currentCategoryId == 'all') {
      categoryName = 'All Stationery';
    } else {
      categoriesAsync.whenData((categories) {
        final match = categories.where((c) => c.id == _currentCategoryId);
        if (match.isNotEmpty) {
          categoryName = match.first.name;
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: productsAsync.when(
          data: (allProducts) {
            // Extract distinct quick filter chips dynamically (sub-categories / tags)
            final quickFilterChips = _extractQuickFilterChips(allProducts, categoryName);

            // Filter & sort products
            final filteredProducts = _filterAndSortProducts(allProducts);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(activeProductsStreamProvider(_currentCategoryId));
                ref.invalidate(activeCategoriesStreamProvider);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── 1. HEADER (Back + Dynamic Category Title + Search + Filter)
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context: context,
                      categoryName: categoryName,
                      allProducts: allProducts,
                    ),
                  ),

                  // ── 2. QUICK FILTER CHIPS (Horizontal Scroll) ───────────
                  SliverToBoxAdapter(
                    child: _buildQuickFilterChips(quickFilterChips),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── 3. SORT & LAYOUT TOOLBAR ─────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildToolbar(
                      context: context,
                      itemCount: filteredProducts.length,
                      allProducts: allProducts,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── 4. PRODUCT GRID / LIST ───────────────────────────────
                  if (filteredProducts.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    )
                  else if (_isGridView)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _ProductListingCard(
                              product: filteredProducts[index],
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProductListingListCard(
                                product: filteredProducts[index],
                              ),
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 35)),
                ],
              ),
            );
          },
          loading: () => _buildLoadingSkeleton(context, categoryName),
          error: (error, _) => _buildErrorState(context, error.toString()),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Header: Back button + Dynamic Category Title + Search + Filter icons
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader({
    required BuildContext context,
    required String categoryName,
    required List<ProductModel> allProducts,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button + Category Title
              Row(
                children: [
                  IconButton(
                    splashRadius: 22,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/categories');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.55,
                    ),
                    child: Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),

              // Search & Filter Action Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    splashRadius: 22,
                    icon: Icon(
                      _isSearchExpanded
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: AppColors.textPrimary,
                      size: 23,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    splashRadius: 22,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textPrimary,
                      size: 23,
                    ),
                    onPressed: () => _showFilterBottomSheet(context, allProducts),
                  ),
                ],
              ),
            ],
          ),

          // Inline Search Bar when search icon is clicked
          if (_isSearchExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Filter in $categoryName...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.textHint,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.royalBlue,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Quick Filter Chips: Horizontally scrollable
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickFilterChips(List<String> chips) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedSubFilter.toLowerCase() == chip.toLowerCase();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedSubFilter = chip;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.royalBlue // Reference Royal Blue
                    : AppColors.surface,  // Ivory / Pure White
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.royalBlue
                      : AppColors.border,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x281A38C9),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                chip,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Toolbar: "Sort by: [Popularity v]" and Grid/List toggle
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildToolbar({
    required BuildContext context,
    required int itemCount,
    required List<ProductModel> allProducts,
  }) {
    String sortLabel = 'Popularity';
    switch (_sortBy) {
      case 'price_low':
        sortLabel = 'Price: Low to High';
        break;
      case 'price_high':
        sortLabel = 'Price: High to Low';
        break;
      case 'newest':
        sortLabel = 'Newest';
        break;
      case 'rating':
        sortLabel = 'Highest Rated';
        break;
      case 'popularity':
      default:
        sortLabel = 'Popularity';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sort by button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showFilterBottomSheet(context, allProducts),
            child: Row(
              children: [
                Text(
                  'Sort by: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sortLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Item Count & Grid/List view toggle
          Row(
            children: [
              Text(
                '$itemCount items',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _isGridView = !_isGridView),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    _isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                    size: 17,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Extract Quick Filter Chips
  // ─────────────────────────────────────────────────────────────────────────
  List<String> _extractQuickFilterChips(
      List<ProductModel> products, String categoryName) {
    final Set<String> chips = {'All'};

    // 1. Extract from product tags
    for (final p in products) {
      for (final t in p.tags) {
        if (t.trim().isNotEmpty && t.length < 18) {
          final formatted = t.trim()[0].toUpperCase() + t.trim().substring(1);
          chips.add(formatted);
          if (chips.length >= 8) break;
        }
      }
    }

    // 2. If no tags found, extract from distinct brands
    if (chips.length <= 1) {
      for (final p in products) {
        final b = p.brandId ?? p.brand;
        if (b.isNotEmpty && b.length < 18) {
          chips.add(b[0].toUpperCase() + b.substring(1));
          if (chips.length >= 7) break;
        }
      }
    }

    // 3. Fallback based on category name if chips still empty
    if (chips.length <= 1) {
      final lower = categoryName.toLowerCase();
      if (lower.contains('notebook') || lower.contains('book')) {
        chips.addAll(['Spiral', 'Hardcover', 'Exercise', 'Ruled', 'Unruled']);
      } else if (lower.contains('pen') || lower.contains('writing')) {
        chips.addAll(['Gel Pens', 'Ball Pens', 'Fountain', 'Markers', 'Highlighters']);
      } else if (lower.contains('art') || lower.contains('craft')) {
        chips.addAll(['Paints', 'Brushes', 'Sketch', 'Crayons', 'Clay']);
      } else if (lower.contains('file') || lower.contains('folder')) {
        chips.addAll(['Ring Binders', 'Clip Files', 'Clear Folders', 'Expanding']);
      }
    }

    return chips.toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter & Sort Products Logic
  // ─────────────────────────────────────────────────────────────────────────
  List<ProductModel> _filterAndSortProducts(List<ProductModel> source) {
    var list = List<ProductModel>.from(source);

    // 1. Search Query filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final descMatch = p.description.toLowerCase().contains(query);
        final tagMatch = p.tags.any((t) => t.toLowerCase().contains(query));
        final brandMatch = (p.brandId ?? p.brand).toLowerCase().contains(query);
        return nameMatch || descMatch || tagMatch || brandMatch;
      }).toList();
    }

    // 2. Quick Sub Filter
    if (_selectedSubFilter != 'All') {
      final chipLower = _selectedSubFilter.toLowerCase();
      list = list.where((p) {
        final tagMatch = p.tags.any((t) => t.toLowerCase().contains(chipLower));
        final nameMatch = p.name.toLowerCase().contains(chipLower);
        final brandMatch = (p.brandId ?? p.brand).toLowerCase().contains(chipLower);
        return tagMatch || nameMatch || brandMatch;
      }).toList();
    }

    // 3. Advanced Price Filter
    if (_priceFilter != 'all') {
      switch (_priceFilter) {
        case 'under_100':
          list = list.where((p) => (p.price / 100) < 100).toList();
          break;
        case '100_300':
          list = list.where((p) => (p.price / 100) >= 100 && (p.price / 100) <= 300).toList();
          break;
        case '300_500':
          list = list.where((p) => (p.price / 100) >= 300 && (p.price / 100) <= 500).toList();
          break;
        case 'above_500':
          list = list.where((p) => (p.price / 100) > 500).toList();
          break;
      }
    }

    // 4. In Stock Filter
    if (_inStockOnly) {
      list = list.where((p) => p.isInStock).toList();
    }

    // 5. On Sale Filter
    if (_onSaleOnly) {
      list = list.where((p) => p.isOnSale).toList();
    }

    // 6. Brand Filter
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      final bLower = _selectedBrand!.toLowerCase();
      list = list.where((p) => (p.brandId ?? p.brand).toLowerCase() == bLower).toList();
    }

    // 7. Sort
    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'popularity':
      default:
        list.sort((a, b) {
          if (a.isBestSeller && !b.isBestSeller) return -1;
          if (!a.isBestSeller && b.isBestSeller) return 1;
          return b.salesCount.compareTo(a.salesCount);
        });
        break;
    }

    return list;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter & Sort Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────
  void _showFilterBottomSheet(
      BuildContext context, List<ProductModel> allProducts) {
    // Extract unique brands
    final Set<String> brands = {};
    for (final p in allProducts) {
      final b = p.brandId ?? p.brand;
      if (b.isNotEmpty) brands.add(b);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title & Reset
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort & Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _resetFilters();
                            });
                            setState(() {
                              _resetFilters();
                            });
                          },
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 16),

                    // Section: Sort By
                    Text(
                      'Sort By',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterRadioChip(
                          label: 'Popularity',
                          selected: _sortBy == 'popularity',
                          onTap: () {
                            setModalState(() => _sortBy = 'popularity');
                            setState(() => _sortBy = 'popularity');
                          },
                        ),
                        _filterRadioChip(
                          label: 'Price: Low to High',
                          selected: _sortBy == 'price_low',
                          onTap: () {
                            setModalState(() => _sortBy = 'price_low');
                            setState(() => _sortBy = 'price_low');
                          },
                        ),
                        _filterRadioChip(
                          label: 'Price: High to Low',
                          selected: _sortBy == 'price_high',
                          onTap: () {
                            setModalState(() => _sortBy = 'price_high');
                            setState(() => _sortBy = 'price_high');
                          },
                        ),
                        _filterRadioChip(
                          label: 'Newest',
                          selected: _sortBy == 'newest',
                          onTap: () {
                            setModalState(() => _sortBy = 'newest');
                            setState(() => _sortBy = 'newest');
                          },
                        ),
                        _filterRadioChip(
                          label: 'Highest Rated',
                          selected: _sortBy == 'rating',
                          onTap: () {
                            setModalState(() => _sortBy = 'rating');
                            setState(() => _sortBy = 'rating');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Section: Price Range
                    Text(
                      'Price Range',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterRadioChip(
                          label: 'All Prices',
                          selected: _priceFilter == 'all',
                          onTap: () {
                            setModalState(() => _priceFilter = 'all');
                            setState(() => _priceFilter = 'all');
                          },
                        ),
                        _filterRadioChip(
                          label: 'Under ₹100',
                          selected: _priceFilter == 'under_100',
                          onTap: () {
                            setModalState(() => _priceFilter = 'under_100');
                            setState(() => _priceFilter = 'under_100');
                          },
                        ),
                        _filterRadioChip(
                          label: '₹100 - ₹300',
                          selected: _priceFilter == '100_300',
                          onTap: () {
                            setModalState(() => _priceFilter = '100_300');
                            setState(() => _priceFilter = '100_300');
                          },
                        ),
                        _filterRadioChip(
                          label: '₹300 - ₹500',
                          selected: _priceFilter == '300_500',
                          onTap: () {
                            setModalState(() => _priceFilter = '300_500');
                            setState(() => _priceFilter = '300_500');
                          },
                        ),
                        _filterRadioChip(
                          label: 'Above ₹500',
                          selected: _priceFilter == 'above_500',
                          onTap: () {
                            setModalState(() => _priceFilter = 'above_500');
                            setState(() => _priceFilter = 'above_500');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Section: Availability & Deals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'In Stock Only',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Switch.adaptive(
                          value: _inStockOnly,
                          activeTrackColor: AppColors.royalBlue,
                          onChanged: (val) {
                            setModalState(() => _inStockOnly = val);
                            setState(() => _inStockOnly = val);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'On Sale / Discounts Only',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Switch.adaptive(
                          value: _onSaleOnly,
                          activeTrackColor: AppColors.royalBlue,
                          onChanged: (val) {
                            setModalState(() => _onSaleOnly = val);
                            setState(() => _onSaleOnly = val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Apply Button
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue, // Royal Blue CTA
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x301A38C9),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _filterRadioChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.royalBlue
              : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.royalBlue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: AppColors.royalBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Products Found',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search query or filters to find what you are looking for.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _resetFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30EE6A2B),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Reset Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load products',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                ref.invalidate(activeProductsStreamProvider(_currentCategoryId));
              },
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading Skeleton
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLoadingSkeleton(BuildContext context, String categoryName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: GridView.builder(
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(18),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT LISTING CARD — Screen 3 Reference Card (Royal Blue Cart, Rating, MRP)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductListingCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductListingCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final wishlistAsync = ref.watch(watchWishlistProvider);
    final p = product;

    final isWishlisted =
        wishlistAsync.value?.any((w) => w.id == p.id) ?? false;
    final qtyInCart = cartState.value
            ?.where((i) => i.productId == p.id)
            .fold(0, (sum, i) => sum + i.qty) ??
        0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real review rating
    final hasReviews = p.reviewCount > 0 && p.averageRating > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.push('/catalog/product/${p.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.border,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. PRODUCT IMAGE WITH WISHLIST BUTTON ──────────
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF242424) : AppColors.surfaceWarm,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: _buildImage(p, context),
                      ),

                      // Wishlist Heart Button (Top Right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (isWishlisted) {
                                ref.read(wishlistProvider.notifier).remove(p.id);
                              } else {
                                ref.read(wishlistProvider.notifier).add(p);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 15,
                                color: isWishlisted
                                    ? AppColors.primary
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. PRODUCT DETAILS & CART ACTION ───────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title & Rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Rating and Reviews Row
                          if (hasReviews)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  p.averageRating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '(${p.reviewCount})',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'No reviews yet',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHint,
                              ),
                            ),
                        ],
                      ),

                      // Prices & Royal Blue Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price & Discount Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      AppFormatters.formatPrice(p.price),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (p.isOnSale) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        AppFormatters.formatPrice(p.mrp),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColors.textHint,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (p.isOnSale) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEFE6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${p.discountPercent}% OFF',
                                      style: GoogleFonts.poppins(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Reference Cart Button: Royal Blue circle or Stepper
                          if (p.isInStock)
                            _buildCartButton(context, ref, qtyInCart, p)
                          else
                            Text(
                              'Sold Out',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHint,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ProductModel p, BuildContext context) {
    if (p.images.isEmpty) {
      return const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 36,
          color: AppColors.border,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: p.images.first,
      fit: BoxFit.contain,
      memCacheWidth: 380,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, err) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: AppColors.border,
        ),
      ),
    );
  }

  Widget _buildCartButton(
      BuildContext context, WidgetRef ref, int qtyInCart, ProductModel p) {
    if (qtyInCart == 0) {
      // Reference Royal Blue Circle with Cart Icon
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(cartProvider.notifier).addItem(p, 1);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added ${p.name} to cart',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                action: SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.push('/cart'),
                ),
                duration: const Duration(milliseconds: 1400),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.royalBlue, // Royal Blue from reference image
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x351A38C9),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Stepper when added to cart
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.royalBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                ref.read(cartProvider.notifier).updateQty(p.id, qtyInCart - 1),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.remove_rounded, size: 13, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$qtyInCart',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (qtyInCart >= p.stock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Maximum available stock reached',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                return;
              }
              ref.read(cartProvider.notifier).updateQty(p.id, qtyInCart + 1);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.add_rounded, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT LISTING LIST CARD (For list-view mode)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductListingListCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductListingListCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final wishlistAsync = ref.watch(watchWishlistProvider);
    final p = product;

    final isWishlisted =
        wishlistAsync.value?.any((w) => w.id == p.id) ?? false;
    final qtyInCart = cartState.value
            ?.where((i) => i.productId == p.id)
            .fold(0, (sum, i) => sum + i.qty) ??
        0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/catalog/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Image
              Container(
                width: 95,
                height: 95,
                color: isDark ? const Color(0xFF242424) : AppColors.surfaceWarm,
                padding: const EdgeInsets.all(8),
                child: p.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.images.first,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, err) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.border,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.border,
                      ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppFormatters.formatPrice(p.price),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (p.isOnSale) ...[
                            const SizedBox(width: 6),
                            Text(
                              AppFormatters.formatPrice(p.mrp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${p.discountPercent}% OFF',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isWishlisted
                            ? AppColors.primary
                            : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () {
                        if (isWishlisted) {
                          ref.read(wishlistProvider.notifier).remove(p.id);
                        } else {
                          ref.read(wishlistProvider.notifier).add(p);
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(p, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added to cart',
                              style: GoogleFonts.poppins(),
                            ),
                            duration: const Duration(milliseconds: 1000),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: qtyInCart > 0 ? AppColors.primary : AppColors.royalBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          qtyInCart > 0 ? Icons.check_rounded : Icons.shopping_bag_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
