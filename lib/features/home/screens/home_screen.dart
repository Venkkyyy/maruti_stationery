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
          backgroundColor: context.colors.background,
          body: CustomScrollView(
              slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: _buildSearch(
                  context,
                  products.map((p) => p.name).toList(),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategories(context, categories, categoriesAsync.isLoading)),
              SliverToBoxAdapter(child: _buildSponsoredAd()),
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
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const SliverToBoxAdapter(child: CouponTicker()),
            SliverToBoxAdapter(child: _buildSearch(context, [])),
            SliverToBoxAdapter(child: _buildSponsoredAd()),
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
            SliverToBoxAdapter(child: _buildSponsoredAd()),
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
      backgroundColor: context.colors.background,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: context.colors.border,
      toolbarHeight: 66,
      automaticallyImplyLeading: false,
      centerTitle: true,
      leadingWidth: 140,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => context.push('/profile/address'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: context.colors.primary, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  fontSize: 11,
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
      title: Container(
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
      actions: [
        GestureDetector(
          onTap: () => context.push('/cart'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.shopping_cart_outlined, color: context.colors.textPrimary, size: 24),
              if (cartCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
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
          child: Icon(Icons.person_outline, color: context.colors.textPrimary, size: 24),
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
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border, width: 1.5),
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
                child: Text(
                  'Search for pens, notebooks, art supplies & more...',
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
                        color: selected ? context.colors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: selected ? null : Border.all(color: context.colors.border.withValues(alpha: 0.5), width: 1),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: context.colors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
        // 6. SHOP BY NEED
        _buildShopByUseCase(realCategories),
        const SizedBox(height: 28),
        // 7. EXPLORE STATIONERY / CATEGORY BUNDLES
        _buildGridCategories('Explore Stationery', realCategories.take(8).toList(), 4),
        const SizedBox(height: 28),
        // 8. TODAY'S BEST DEALS
        if (offeredProducts.isNotEmpty) ...[
          _buildBundleSection('🔥 Today\'s Best Deals', 'Unbeatable prices just for you', offeredProducts.take(8).toList(), ads: activeAds, badgeColor: const Color(0xFFE53935)),
          const SizedBox(height: 28),
        ],
        // 9. BACK TO SCHOOL / SEASONAL COLLECTION
        _buildSeasonalCollection(),
        const SizedBox(height: 28),
        // 10. PRODUCT BUNDLES
        _buildProductBundles(products.take(3).toList()),
        const SizedBox(height: 28),
        // 11. BUY TOGETHER & SAVE
        _buildBuyTogether(products.skip(3).take(3).toList()),
        const SizedBox(height: 28),
        // 12. TRENDING NOW
        if (trendingProducts.isNotEmpty) ...[
          _buildBundleSection('📈 Trending Now', 'Hot & selling fast', trendingProducts.take(8).toList(), ads: activeAds, badgeColor: const Color(0xFF1B2D6E)),
          const SizedBox(height: 28),
        ],
        // 13. FREQUENTLY BOUGHT TOGETHER
        _buildFrequentlyBought(products.take(4).toList()),
        const SizedBox(height: 28),
        // 14. SHOP BY BRAND
        _buildTopBrands(ref),
        const SizedBox(height: 32),
        // 15. BEST SELLERS
        if (bestSellerProducts.isNotEmpty) ...[
          _buildBundleSection('🏆 Best Sellers', 'Top picks by our customers', bestSellerProducts.take(8).toList(), ads: activeAds, badgeColor: const Color(0xFFFF6B00)),
          const SizedBox(height: 28),
        ],
        // 16. PICKED FOR YOU
        _buildBundleSection('💡 Picked for You', 'Curated just for you', topRatedProducts.skip(4).take(8).toList(), ads: activeAds, badgeColor: const Color(0xFF1B2D6E)),
        const SizedBox(height: 28),
        // 17. RECENTLY BOUGHT / BUY AGAIN
        if (buyAgainProducts.isNotEmpty) ...[
          _buildBundleSection('🔄 Buy Again', 'Your recent picks', buyAgainProducts.take(8).toList(), ads: activeAds, badgeColor: const Color(0xFF00897B)),
          const SizedBox(height: 28),
        ],
        // 18. NEW ARRIVALS
        if (newArrivals.isNotEmpty) ...[
          _buildBundleSection('✨ New Arrivals', 'Fresh stock just landed', newArrivals.take(8).toList(), ads: activeAds, badgeColor: const Color(0xFF7B1FA2)),
          const SizedBox(height: 28),
        ],
        // 19. PREMIUM COLLECTIONS
        _buildPremiumCollections(),
        const SizedBox(height: 28),
        // 20. MORE DEALS / PROMOTIONS
        _buildDummyBanner('Stationery for Every Dream', 'We\'ve got you covered!', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
        const SizedBox(height: 32),
        // 21. SERVICE BENEFITS
        _buildServiceBenefits(),
        const SizedBox(height: 32),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title.replaceAll(RegExp(r'^[^\w]+ '), ''), // Remove emojis if any
                style: AppTextStyles.sectionTitle.copyWith(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: onViewMore ?? () => context.go('/catalog'),
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: AppTextStyles.sectionLink.copyWith(
                        color: context.colors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: context.colors.primary,
                      size: 16,
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
        SizedBox(
          height: 120, // fixed height for horizontal category list
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final bgColor = const Color(0xFFFFF0DE); // Light Peach #FFF0DE
              return GestureDetector(
                onTap: () {
                  context.go('/catalog?categoryId=${cat.id}');
                },
                child: Container(
                  width: 90, // fixed width slightly larger than product cards
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: cat.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: cat.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, _) => Container(color: bgColor),
                                errorWidget: (context, _, __) => Icon(Icons.category, color: context.colors.primary, size: 28),
                              )
                            : Icon(Icons.category, color: context.colors.primary, size: 32),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Shop by Use Case',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/categories'),
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: AppTextStyles.sectionLink.copyWith(
                        color: context.colors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: context.colors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120, // Match the height of Category bundle
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final bgColor = const Color(0xFFFFF0DE); // Light Peach #FFF0DE
              
              return GestureDetector(
                onTap: () {
                  context.go('/catalog?categoryId=${cat.id}');
                },
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: cat.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: cat.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, _) => Container(color: bgColor),
                                errorWidget: (context, _, __) => Icon(Icons.work_outline, color: context.colors.primary, size: 28),
                              )
                            : Icon(Icons.work_outline, color: context.colors.primary, size: 32),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          '${cat.name.split(' ').first}\nEssentials',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
  }
  Widget _buildSponsoredAd() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Sponsored', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: context.colors.textSecondary)),
                ),
                const SizedBox(height: 8),
                Text('CAMLIN ART COLLECTION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: context.colors.textPrimary)),
                const SizedBox(height: 4),
                Text('Create. Colour. Imagine.', style: TextStyle(fontSize: 10, color: context.colors.textHint)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('SHOP NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.brush, color: Colors.orange, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBundles(List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Product Bundles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              return Container(
                width: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BACK TO SCHOOL KIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.colors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('📓 ✏️ 🧽 📐 🖊️', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text('5 essentials', style: TextStyle(fontSize: 10, color: context.colors.textHint)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹299', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                            Text('₹399', style: TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: context.colors.textHint)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text('ADD KIT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  Widget _buildBuyTogether(List<ProductModel> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Buy Together & Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0DE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notebook + Pens', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('₹280', style: TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: context.colors.textHint)),
                    Text('₹219', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.colors.primary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFDFF3D8), borderRadius: BorderRadius.circular(4)),
                      child: const Text('SAVE ₹61', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('ADD BUNDLE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequentlyBought(List<ProductModel> products) {
    if (products.length < 4) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Frequently Bought Together', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i=0; i<4; i++) ...[
                    if (i > 0) const Icon(Icons.add, size: 16, color: Colors.grey),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: products[i].images.isNotEmpty 
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: products[i].images.first, fit: BoxFit.cover))
                        : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Add All 4 Items'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonalCollection() {
    return _buildDummyBanner('Back to School', 'Gear up for the new term!', const Color(0xFFE3F2FD), const Color(0xFF1976D2));
  }

  Widget _buildPremiumCollections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Premium Collections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildCollectionCard('Premium Writing', 'Craftsmanship meets style', const Color(0xFF424242)),
              const SizedBox(width: 12),
              _buildCollectionCard('Study Desk', 'Organize your space', const Color(0xFF00796B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(String title, String subtitle, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildServiceBenefits() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBenefitItem('🚚', 'Fast Delivery'),
          _buildBenefitItem('🔒', 'Secure Payments'),
          _buildBenefitItem('↩️', 'Easy Returns'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0DE), // light peach
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    banner.title ?? 'Back to School',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Essentials',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: context.colors.textPrimary,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Everything you need\nfor a brighter tomorrow',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: context.colors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Shop Now →',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        // Offer Badge
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F), // Yellow badge
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('UP TO', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                                Text('40%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: context.colors.textPrimary, height: 1.0)),
                                Text('OFF', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
