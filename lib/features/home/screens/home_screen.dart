import 'dart:async';
import 'dart:ui';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../catalog/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/coupon_ticker.dart';
import '../../../shared/widgets/coupon_popup.dart';
import '../../../providers/coupon_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/banner_provider.dart';
import '../../../models/banner_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/categories_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animated_search_hint.dart';
import '../../../providers/ads_provider.dart';
import '../../../providers/brand_provider.dart';
import '../../../models/brand_model.dart';
import '../../../models/ad_model.dart';
import '../../catalog/widgets/ad_card.dart';
import '../../../providers/address_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;
  String _sortBy = 'newest';
  final Set<String> _loggedImpressions = {};

  List<Widget> _buildAdInjectedSlivers({
    required List<ProductModel> products,
    required List<AdModel> ads,
    required double topPadding,
  }) {
    List<dynamic> combinedItems = [];
    
    if (ads.isEmpty) {
      combinedItems.addAll(products);
    } else {
      final freq = ads.first.placementFrequency.clamp(2, 100);
      int adRotationIndex = 0;
      
      for (int i = 0; i < products.length; i++) {
        combinedItems.add(products[i]);
        if ((i + 1) % freq == 0) {
          combinedItems.add(ads[adRotationIndex % ads.length]);
          adRotationIndex++;
        }
      }
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 32),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.58,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = combinedItems[index];
              if (item is ProductModel) {
                return ProductCard(product: item);
              } else if (item is AdModel) {
                return AdCard(
                  ad: item,
                  loggedImpressions: _loggedImpressions,
                );
              }
              return const SizedBox.shrink();
            },
            childCount: combinedItems.length,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Listen for active coupons to show one-time popup
    ref.listen(watchActiveCouponsProvider, (previous, next) async {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final latestCoupon = next.value!.first;
        final prefs = await SharedPreferences.getInstance();
        final lastSeenId = prefs.getString('last_seen_coupon_id');

        if (lastSeenId != latestCoupon.id) {
          await prefs.setString('last_seen_coupon_id', latestCoupon.id);
          if (context.mounted) {
            showDialog(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.8),
              builder: (context) => CouponPopup(coupon: latestCoupon),
            );
          }
        }
      }
    });

    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
    final List<CategoryModel> categories = [
      CategoryModel(
        id: 'all',
        name: 'All',
        image: '',
        order: -1,
        isActive: true,
      ),
      ...(categoriesAsync.value ?? []),
    ];

    if (_selectedCategory >= categories.length) {
      _selectedCategory = 0;
    }

    final currentCatId = categories[_selectedCategory].id;
    final productsAsync = ref.watch(activeProductsStreamProvider(currentCatId));

    final activeAdsAsync = ref.watch(activeAdsProvider);
    final activeAds = activeAdsAsync.when(
      data: (ads) => ads,
      loading: () => <AdModel>[],
      error: (_, _) => <AdModel>[],
    );

    return productsAsync.when(
      data: (products) {
        final isAll = _selectedCategory == 0;
        
        List<ProductModel> displayProducts = List.from(products);
        if (_sortBy == 'price_low') {
          displayProducts.sort((a, b) => a.price.compareTo(b.price));
        } else if (_sortBy == 'price_high') {
          displayProducts.sort((a, b) => b.price.compareTo(a.price));
        } else {
          displayProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEFF6FF),
                  Color(0xFFFFF1F2),
                  Color(0xFFF0FDF4),
                  Color(0xFFF8FAFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: CustomScrollView(
              slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: _buildSearch(
                  context,
                  products.map((p) => p.name).toList(),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategories(context, categories, categoriesAsync.isLoading)),
              SliverToBoxAdapter(child: _buildBanners(context, ref)),

              if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No products available',
                        style: TextStyle(color: context.colors.textHint),
                      ),
                    ),
                  ),
                )
              else if (isAll) ...[
                // The exact layout as per design
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final user = ref.watch(authStateProvider).value;
                      if (user == null) {
                        return _buildFullHomepageLayout(
                          products,
                          categories,
                          activeAds,
                          [],
                          ref,
                        );
                      }
                      return ref
                          .watch(watchUserOrdersProvider(user.uid))
                          .when(
                            data: (orders) {
                              final pastProductIds = <String>{};
                              for (final order in orders) {
                                for (final item in order.items) {
                                  pastProductIds.add(item.productId);
                                }
                              }
                              final buyAgainProducts = products
                                  .where((p) => pastProductIds.contains(p.id))
                                  .toList();
                              return _buildFullHomepageLayout(
                                products,
                                categories,
                                activeAds,
                                buyAgainProducts,
                                ref,
                              );
                            },
                            loading: () => _buildFullHomepageLayout(
                              products,
                              categories,
                              activeAds,
                              [],
                              ref,
                            ),
                            error: (_, _) => _buildFullHomepageLayout(
                              products,
                              categories,
                              activeAds,
                              [],
                              ref,
                            ),
                          );
                    },
                  ),
                ),
              ] else ...[
                // Category specific grid
                ..._buildAdInjectedSlivers(
                  products: displayProducts,
                  ads: activeAds,
                  topPadding: 24.0,
                ),
              ],
              if (products.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Divider(
                            color: context.colors.border,
                            endIndent: 16,
                            indent: 32,
                            thickness: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.colors.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'MARUTI STATIONERY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: context.colors.border,
                            indent: 16,
                            endIndent: 32,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const SliverToBoxAdapter(child: CouponTicker()),
            SliverToBoxAdapter(child: _buildSearch(context, [])),
            SliverToBoxAdapter(child: _buildBanners(context, ref)),
            SliverToBoxAdapter(child: _buildCategories(context, [], true)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const SliverToBoxAdapter(child: CouponTicker()),
            SliverToBoxAdapter(child: _buildSearch(context, [])),
            SliverToBoxAdapter(child: _buildBanners(context, ref)),
            SliverToBoxAdapter(child: _buildCategories(context, [], false)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final cartCount = ref
            .watch(cartProvider)
            .value
            ?.fold<int>(0, (total, i) => total + i.qty) ??
        0;
    
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: context.colors.border,
      toolbarHeight: 66,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Deliver To Section (Left)
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/profile/address'),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: context.colors.primary, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Deliver to',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final addressesAsync = ref.watch(addressProvider);
                            final addressStr = addressesAsync.when(
                              data: (addresses) {
                                if (addresses.isEmpty) return 'Add Address';
                                final defaultAddr = addresses.first;
                                return '${defaultAddr.street}, ${defaultAddr.city}';
                              },
                              loading: () => 'Loading...',
                              error: (_, __) => 'Error',
                            );
                            return Flexible(
                              child: Text(
                                addressStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logo Section (Middle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: context.colors.primary,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maruti',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'Stationery',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary.withValues(alpha: 0.8),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right spacer for symmetry (optional, or rely on actions)
          const Spacer(),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => context.push('/cart'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.shopping_cart_outlined, color: context.colors.primary, size: 24),
                  if (cartCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Icon(Icons.person_outline, color: context.colors.primary, size: 24),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBanners(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannerProvider);

    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return _AutoBannerSlider(banners: banners);
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearch(BuildContext context, List<String> productNames) {
    // Use real product names — take up to 8, fallback to stationery defaults
    final hints = productNames.isNotEmpty
        ? (productNames..shuffle()).take(8).toList()
        : const [
            'pens',
            'notebooks',
            'art supplies',
            'school bags',
            'geometry boxes',
            'files & folders',
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF3F6F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: context.colors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSearchHint(
                  hints: hints,
                  style: TextStyle(
                    color: context.colors.textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context, List<CategoryModel> categories, bool isLoading) {
    if (isLoading && categories.length <= 1) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Some pastel colors for the category backgrounds
    final List<Color> pastelColors = [
      const Color(0xFFF3E5F5), // Light purple
      const Color(0xFFE3F2FD), // Light blue
      const Color(0xFFFBE9E7), // Light orange
      const Color(0xFFE8F5E9), // Light green
      const Color(0xFFFFF8E1), // Light yellow
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final bool selected = _selectedCategory == i;
              final cat = categories[i];
              final bgColor = pastelColors[i % pastelColors.length];
              
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = i);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: selected ? context.colors.primary : bgColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: context.colors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: i == 0
                          ? Icon(
                              Icons.grid_view_rounded,
                              size: 24,
                              color: selected ? Colors.white : context.colors.primary,
                            )
                          : cat.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cat.image, 
                              fit: BoxFit.cover,
                              memCacheWidth: 150,
                              placeholder: (context, url) => Container(color: bgColor),
                              errorWidget: (context, url, error) => Icon(
                                Icons.category_rounded,
                                size: 24,
                                color: selected ? Colors.white : context.colors.primary,
                              ),
                            )
                          : Icon(
                              Icons.category_rounded,
                              size: 24,
                              color: selected ? Colors.white : context.colors.primary,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? context.colors.primary : context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullHomepageLayout(
    List<ProductModel> products,
    List<CategoryModel> categories,
    List<AdModel> activeAds,
    List<ProductModel> buyAgainProducts,
    WidgetRef ref,
  ) {
    final offeredProducts = products.where((p) => p.isOnSale).toList();
    final bestSellerProducts = products.where((p) => p.isBestSeller).toList();
    final trendingProducts = products.toList()
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    final topRatedProducts = products.toList()
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    final newArrivals = products.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final realCategories = categories.where((c) => c.id != 'all').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // ── BUNDLE 1: Shop by Category grid ──────────────────────────────
        _buildGridCategories(
            'Shop by Category', realCategories.take(8).toList(), 4),
        const SizedBox(height: 28),

        // ── BUNDLE 2: Buy Again (personalized) ───────────────────────────
        if (buyAgainProducts.isNotEmpty) ...[
          _buildBundleSection(
            '🔄  Buy Again',
            'Your recent picks',
            buyAgainProducts.take(8).toList(),
            ads: activeAds,
            isHighlighted: true,
            badgeColor: const Color(0xFF1B2D6E),
          ),
          const SizedBox(height: 24),
        ],

        // ── BUNDLE 3: Best Sellers ────────────────────────────────────────
        if (bestSellerProducts.isNotEmpty) ...[
          _buildBundleSection(
            '🏆  Best Sellers',
            'Top picks by our customers',
            bestSellerProducts.take(8).toList(),
            ads: activeAds,
            isHighlighted: true,
            badgeColor: const Color(0xFFFF6B00),
          ),
          const SizedBox(height: 24),
        ],

        // ── BUNDLE 4: Trending Now ────────────────────────────────────────
        _buildBundleSection(
          '🔥  Trending Now',
          'Hot & selling fast',
          trendingProducts.take(8).toList(),
          ads: activeAds,
          badgeColor: const Color(0xFFE53935),
        ),
        const SizedBox(height: 28),

        // ── Category bundles (per real category) ─────────────────────────
        ..._buildCategoryBundles(realCategories, products, activeAds),

        // ── DEALS Banner (ads) ────────────────────────────────────────────
        _buildAdsHorizontalSection(activeAds),

        // ── BUNDLE 5: Featured / Top Rated ───────────────────────────────
        _buildBundleSection(
          '⭐  Featured Products',
          'Highly rated by shoppers',
          topRatedProducts.take(8).toList(),
          ads: activeAds,
          isHighlighted: true,
          badgeColor: const Color(0xFFFBC02D),
        ),
        const SizedBox(height: 28),

        // ── Promotional Banner 1 ──────────────────────────────────────────
        _buildDummyBanner(
          'Office Essentials',
          'Work Smarter Not Harder',
          const Color(0xFFE3F2FD),
          const Color(0xFF1976D2),
        ),
        const SizedBox(height: 32),

        // ── Popular Categories: secondary grid ────────────────────────────
        _buildGridCategories(
            'Popular Categories',
            realCategories.skip(8).take(8).toList(),
            4),
        const SizedBox(height: 28),

        // ── BUNDLE 6: Special Offers / Deals ─────────────────────────────
        if (offeredProducts.isNotEmpty) ...[
          _buildBundleSection(
            '🎁  Special Offers',
            'Prices slashed just for you',
            offeredProducts.take(8).toList(),
            ads: activeAds,
            isHighlighted: true,
            badgeColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 24),
        ],

        // ── BUNDLE 7: New Arrivals ────────────────────────────────────────
        _buildBundleSection(
          '✨  New Arrivals',
          'Fresh stock just landed',
          newArrivals.take(8).toList(),
          ads: activeAds,
          badgeColor: const Color(0xFF7B1FA2),
        ),
        const SizedBox(height: 28),

        // ── Top Brands ────────────────────────────────────────────────────
        _buildTopBrands(ref),
        const SizedBox(height: 32),

        // ── Promotional Banner 2 ──────────────────────────────────────────
        _buildDummyBanner(
          'Quality Stationery',
          'for a Better Tomorrow',
          const Color(0xFFEDE7F6),
          const Color(0xFF512DA8),
        ),
        const SizedBox(height: 32),

        // ── BUNDLE 8: Recommended for You (top-rated) ────────────────────
        _buildBundleSection(
          '💡  Recommended for You',
          'Curated just for you',
          topRatedProducts.skip(4).take(8).toList(),
          ads: activeAds,
          isHighlighted: true,
          badgeColor: const Color(0xFF1B2D6E),
        ),
        const SizedBox(height: 24),

        // ── Shop by Use Case ─────────────────────────────────────────────
        _buildShopByUseCase(realCategories),
        const SizedBox(height: 32),

        // ── Explore More grid ────────────────────────────────────────────
        _buildGridCategories(
          'Explore More',
          realCategories.skip(16).take(8).toList(),
          4,
          isHighlighted: true,
        ),
        const SizedBox(height: 24),

        // ── Final Promo Banner ───────────────────────────────────────────
        _buildDummyBanner(
          'Stationery for Every Dream',
          'We\'ve got you covered!',
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
        ),
        const SizedBox(height: 32),

        // ── More Popular Items ────────────────────────────────────────────
        _buildBundleSection(
          '📦  More Popular Items',
          'Don\'t miss out',
          trendingProducts.skip(8).take(8).toList(),
          ads: activeAds,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Per-category bundle sections (Blinkit-style) ──────────────────────────
  List<Widget> _buildCategoryBundles(
    List<CategoryModel> categories,
    List<ProductModel> allProducts,
    List<AdModel> ads,
  ) {
    final widgets = <Widget>[];
    final bundleColors = [
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFC62828),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
      const Color(0xFFE65100),
    ];

    for (int i = 0; i < categories.length && i < 6; i++) {
      final cat = categories[i];
      final catProducts =
          allProducts.where((p) => p.categoryId == cat.id).toList();
      if (catProducts.isEmpty) continue;

      widgets.add(
        _buildBundleSection(
          cat.name,
          '${catProducts.length} products',
          catProducts.take(8).toList(),
          ads: ads,
          isHighlighted: i.isEven,
          badgeColor: bundleColors[i % bundleColors.length],
          onViewMore: () =>
              context.go('/catalog?categoryId=${cat.id}'),
        ),
      );
      widgets.add(const SizedBox(height: 24));
    }
    return widgets;
  }

  // ── Premium bundle section widget ─────────────────────────────────────────
  Widget _buildBundleSection(
    String title,
    String subtitle,
    List<ProductModel> products, {
    List<AdModel> ads = const [],
    bool isHighlighted = false,
    Color badgeColor = const Color(0xFF1B2D6E),
    VoidCallback? onViewMore,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.sectionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal product list
        SizedBox(
          height: 265,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 158,
              child: ProductCard(product: products[i]),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // "See all products >" footer button (Blinkit/Zepto style)
        Center(
          child: GestureDetector(
            onTap: onViewMore ?? () => context.go('/catalog'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stack of product images
                  if (products.isNotEmpty)
                    SizedBox(
                      width: (products.length >= 3 ? 3 : products.length) * 16.0 + 10.0,
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(
                          products.length >= 3 ? 3 : products.length,
                          (index) => Positioned(
                            left: index * 14.0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                color: const Color(0xFFF5F6FA),
                              ),
                              child: ClipOval(
                                child: products[index].images.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: products[index].images.first,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Icon(
                                            Icons.image,
                                            size: 12,
                                            color: context.colors.textHint),
                                      )
                                    : Icon(Icons.image,
                                        size: 12, color: context.colors.textHint),
                              ),
                            ),
                          ),
                        ).reversed.toList(), // Reversed to stack correctly (first on top)
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'See all products',
                    style: TextStyle(
                      color: context.colors.textPrimary.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textPrimary.withValues(alpha: 0.9),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );

    if (isHighlighted) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }
    return content;
  }

  Widget _buildHorizontalProductSection(
    String title,
    List<ProductModel> products, {
    bool showViewMore = false,
    bool isHighlighted = false,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (showViewMore)
                GestureDetector(
                  onTap: () => context.go('/catalog'),
                  child: Row(
                    children: [
                      Text('View more', style: AppTextStyles.sectionLink),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 260, // Adjusted for new ProductCard height
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return SizedBox(
                width: 155, // Slightly narrower for horizontal scroll
                child: ProductCard(product: products[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );

    if (isHighlighted) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4), // Glass effect over continuous gradient
              border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: content,
          ),
        ),
      );
    }
    
    return content;
  }

  Widget _buildAdsHorizontalSection(List<AdModel> ads) {
    if (ads.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Deals on Stationery', style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return SizedBox(
                width: 180,
                child: AdCard(
                  ad: ads[i],
                  loggedImpressions: _loggedImpressions,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGridCategories(String title, List<CategoryModel> categories, int crossAxisCount, {bool isHighlighted = false}) {
    if (categories.isEmpty) return const SizedBox.shrink();
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              GestureDetector(
                onTap: () => context.go('/categories'),
                child: Row(
                  children: [
                    Text('See all', style: AppTextStyles.sectionLink),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: context.colors.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount == 4 ? 0.75 : (crossAxisCount == 3 ? 0.8 : 0.9),
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final colors = [
              const Color(0xFFFFF3E0), const Color(0xFFE3F2FD), 
              const Color(0xFFF3E5F5), const Color(0xFFE8F5E9), 
              const Color(0xFFFFEBEE), const Color(0xFFE0F7FA)
            ];
            final bgColor = colors[index % colors.length];
            return GestureDetector(
              onTap: () {
                context.go('/catalog?categoryId=${cat.id}');
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: cat.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cat.image,
                              fit: BoxFit.cover,
                              placeholder: (context, _) => Container(color: bgColor),
                              errorWidget: (context, _, __) => Icon(Icons.category, color: context.colors.textSecondary),
                            )
                          : Icon(Icons.category, color: context.colors.primary, size: 32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: crossAxisCount == 4 ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );

    if (isHighlighted) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4), // Glass effect
              border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: content,
          ),
        ),
      );
    }
    
    return content;
  }

  Widget _buildDummyBanner(String title, String subtitle, Color bgColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor.withValues(alpha: 0.6), bgColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [textColor.withValues(alpha: 0.8), textColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Shop Now →',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.shopping_bag, size: 64, color: Colors.black12),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBrands(WidgetRef ref) {
    final brandsAsync = ref.watch(watchBrandsProvider);
    return brandsAsync.when(
      data: (brands) {
        final activeBrands = brands.where((b) => b.isActive).toList();
        if (activeBrands.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Top Brands', style: AppTextStyles.sectionTitle),
                  Text('See all →', style: AppTextStyles.sectionLink),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: activeBrands.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final brand = activeBrands[i];
                  return GestureDetector(
                    onTap: () {
                      context.push('/search?q=${Uri.encodeComponent(brand.name)}');
                    },
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: context.colors.border),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: brand.logoUrl.isNotEmpty 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: brand.logoUrl,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 60,
                              errorWidget: (context, url, error) => _buildBrandTextFallback(context, brand.name),
                            ),
                          )
                        : _buildBrandTextFallback(context, brand.name),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBrandTextFallback(BuildContext context, String name) {
    return Text(
      name,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: context.colors.primary,
      ),
    );
  }

  Widget _buildShopByUseCase(List<CategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shop by Use Case', style: AppTextStyles.sectionTitle),
              Text('See all →', style: AppTextStyles.sectionLink),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_outline, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${cat.name.split(' ').first} \nEssentials',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: context.colors.textPrimary, height: 1.1),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AutoBannerSlider extends StatefulWidget {
  final List<BannerModel> banners;

  const _AutoBannerSlider({required this.banners});

  @override
  State<_AutoBannerSlider> createState() => _AutoBannerSliderState();
}

class _AutoBannerSliderState extends State<_AutoBannerSlider> {
  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(_AutoBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length) {
      if (_currentPage >= widget.banners.length) {
        _currentPage = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || widget.banners.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onBannerTap(BannerModel banner, BuildContext context) {
    if (banner.tag != null) {
      final title = Uri.encodeComponent(banner.title ?? banner.tag!);
      context.push('/banner-products?tag=${banner.tag}&title=$title');
    } else if (banner.targetCategoryId != null) {
      context.go('/catalog?categoryId=${banner.targetCategoryId}');
    } else if (banner.targetProductId != null) {
      context.push('/catalog/product/${banner.targetProductId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                final bool hasLink =
                    banner.tag != null ||
                    banner.targetCategoryId != null ||
                    banner.targetProductId != null;
                return GestureDetector(
                  onTap: hasLink ? () => _onBannerTap(banner, context) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(banner.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: hasLink
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          // Dot indicators
          if (widget.banners.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (i) {
                final isActive = i == (_currentPage % widget.banners.length);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? context.colors.primary
                        : context.colors.primary.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
