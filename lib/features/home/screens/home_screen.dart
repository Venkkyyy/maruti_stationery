import 'dart:async';
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
import '../../../shared/widgets/animated_search_hint.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;

  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('categories').orderBy('order').get();
      final cats = snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
      
      // Prepend "All"
      cats.insert(0, CategoryModel(id: 'all', name: 'All', image: '', order: -1, isActive: true));
      
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
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
              barrierColor: Colors.black.withOpacity(0.8),
              builder: (context) => CouponPopup(coupon: latestCoupon),
            );
          }
        }
      }
    });

    final productsAsync = _selectedCategory == 0 || _categories.isEmpty
        ? ref.watch(getNewArrivalsProvider(limit: 20)) // Load more for All Products grid
        : ref.watch(getProductsByCategoryProvider(_categories[_selectedCategory].id));

    return productsAsync.when(
      data: (products) {
        final isAll = _selectedCategory == 0;
        final trendingProducts = products.toList()..sort((a, b) => b.salesCount.compareTo(a.salesCount));
        final topRatedProducts = products.toList()..sort((a, b) => b.averageRating.compareTo(a.averageRating));

        return Scaffold(
          backgroundColor: context.colors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              const SliverToBoxAdapter(child: CouponTicker()),
              SliverToBoxAdapter(child: _buildHeader(context, products.map((p) => p.name).toList())),
              SliverToBoxAdapter(child: _buildBanners(context, ref)),
              
              if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('No products available', style: TextStyle(color: context.colors.textHint))),
                  ),
                )
              else if (isAll) ...[
                // Buy Again and horizontal sections
                SliverToBoxAdapter(
                  child: Consumer(builder: (context, ref, _) {
                    final user = ref.watch(authStateProvider).value;
                    if (user == null) {
                      return _buildHorizontalSections(trendingProducts, topRatedProducts, []);
                    }
                    return ref.watch(watchUserOrdersProvider(user.uid)).when(
                      data: (orders) {
                        final pastProductIds = <String>{};
                        for (final order in orders) {
                          for (final item in order.items) pastProductIds.add(item.productId);
                        }
                        final buyAgainProducts = products.where((p) => pastProductIds.contains(p.id)).toList();
                        return _buildHorizontalSections(trendingProducts, topRatedProducts, buyAgainProducts);
                      },
                      loading: () => _buildHorizontalSections(trendingProducts, topRatedProducts, []),
                      error: (_, __) => _buildHorizontalSections(trendingProducts, topRatedProducts, []),
                    );
                  }),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text('All Products', style: AppTextStyles.sectionTitle),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58, // Adjusted for new ProductCard height
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  ),
                ),
              ] else ...[
                // Category specific grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24).copyWith(bottom: 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58, // Adjusted for new ProductCard height
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  ),
                ),
              ],
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
            SliverToBoxAdapter(child: _buildHeader(context, [])),
            SliverToBoxAdapter(child: _buildBanners(context, ref)),
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const SliverToBoxAdapter(child: CouponTicker()),
            SliverToBoxAdapter(child: _buildHeader(context, [])),
            SliverToBoxAdapter(child: _buildBanners(context, ref)),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Error: $e')))),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: context.colors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: context.colors.border,
      leading: IconButton(
        icon: Icon(Icons.notifications_none_rounded, color: context.colors.textPrimary),
        onPressed: () => context.push('/home/notifications'),
      ),
      centerTitle: true,
      title: Text(
        'Maruti Stationery',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.colors.primary,
        ),
      ),
      actions: [
        const SizedBox(width: 4),
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
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(BuildContext context, List<String> productNames) {
    final searchHints = productNames.take(10).toList();
    if (searchHints.isEmpty) searchHints.addAll(['atta', 'dal', 'coke']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => context.go('/search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.black87, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSearchHint(
                      hints: searchHints,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Category Chips
        if (_isLoadingCategories)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final bool selected = _selectedCategory == i;
                final cat = _categories[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: selected ? context.colors.primary.withValues(alpha: 0.1) : const Color(0xFFF4F6F8),
                          shape: BoxShape.circle,
                        ),
                        child: i == 0 
                            ? Icon(Icons.grid_view_rounded, size: 24, color: selected ? context.colors.primary : Colors.black87)
                            : cat.image.isNotEmpty
                                ? Image.network(cat.image, fit: BoxFit.cover)
                                : Icon(Icons.category_outlined, size: 24, color: selected ? context.colors.primary : Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? context.colors.primary : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        // A thin divider below categories like the image
        Container(
          height: 4,
          color: const Color(0xFFF1F2F4),
        ),
      ],
    );
  }

  Widget _buildHorizontalSections(
    List<ProductModel> trendingProducts,
    List<ProductModel> topRatedProducts,
    List<ProductModel> buyAgainProducts,
  ) {
    return Column(
      children: [
        _buildHorizontalProductSection('Featured', trendingProducts.take(6).toList(), showViewMore: true),
        _buildHorizontalProductSection('Trending', topRatedProducts.take(6).toList()),
        _buildHorizontalProductSection('Buy Again', buyAgainProducts.take(6).toList()),
      ],
    );
  }

  Widget _buildHorizontalProductSection(String title, List<ProductModel> products, {bool showViewMore = false}) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
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
                      Icon(Icons.chevron_right_rounded, color: context.colors.primary, size: 18),
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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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
  }
}

class _AutoBannerSlider extends StatefulWidget {
  final List banners;

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

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
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

  void _onBannerTap(dynamic banner, BuildContext context) {
    if (banner.targetCategoryId != null) {
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
                    banner.targetCategoryId != null || banner.targetProductId != null;
                return GestureDetector(
                  onTap: hasLink ? () => _onBannerTap(banner, context) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(banner.imageUrl),
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
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
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
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withValues(alpha: 0.3),
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




