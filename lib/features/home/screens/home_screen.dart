import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../models/banner_model.dart';
import '../../../models/ad_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/banner_provider.dart';
import '../../../providers/ads_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/address_provider.dart';
import '../../catalog/widgets/product_card.dart';
import '../../../shared/widgets/coupon_popup.dart';
import '../../../providers/coupon_provider.dart';
import '../../../models/home_section_model.dart';
import '../../../providers/home_layout_provider.dart';
import '../../../shared/widgets/animated_search_hint.dart';
import '../../../models/storefront_section_model.dart';
import '../../../providers/storefront_provider.dart';
import '../../../providers/brand_provider.dart';
import '../../../models/brand_model.dart';
import '../../../models/product_collection_model.dart';
import '../../../shared/sdui/storefront_section_renderer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _loggedImpressions = {};
  String _selectedCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    // Listen for active coupons
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
              barrierColor: Colors.black.withValues(alpha: 0.75),
              builder: (context) => CouponPopup(coupon: latestCoupon),
            );
          }
        }
      }
    });

    final storefrontAsync = ref.watch(publishedStorefrontStreamProvider('home'));
    final collections = ref.watch(productCollectionsStreamProvider).value ?? [];
    final brands = ref.watch(watchBrandsProvider).value ?? [];
    final banners = ref.watch(bannerProvider).value ?? [];
    final categories = ref.watch(activeCategoriesStreamProvider).value ?? [];
    final allProducts = ref.watch(activeProductsStreamProvider('all')).value ?? [];
    final ads = ref.watch(activeAdsProvider).value ?? [];
    final sections = storefrontAsync.value?.sections ?? StorefrontSectionModel.defaultSections;

    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;

    final addressesAsync = ref.watch(addressProvider);
    final String selectedAddress = addressesAsync.value?.isNotEmpty == true
        ? '${addressesAsync.value!.first.street}, ${addressesAsync.value!.first.city}'
        : 'flat, surat';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(publishedStorefrontStreamProvider('home'));
            ref.invalidate(productCollectionsStreamProvider);
            ref.invalidate(watchBrandsProvider);
            ref.invalidate(bannerProvider);
            ref.invalidate(activeCategoriesStreamProvider);
            ref.invalidate(activeProductsStreamProvider('all'));
            ref.invalidate(activeAdsProvider);
            ref.invalidate(addressProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── 1. HEADER (Deliver to + Maruti Stationery Logo + Search) ─
              SliverToBoxAdapter(
                child: _buildReferenceHeader(
                  context: context,
                  addressText: selectedAddress,
                ),
              ),

              // ── DYNAMIC SERVER-DRIVEN UI SECTIONS ─────────────────────────
              ..._buildDynamicSections(
                context: context,
                sections: sections,
                categories: categories,
                banners: banners,
                allProducts: allProducts,
                ads: ads,
                brands: brands,
                collections: collections,
                currentUser: currentUser,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 35)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Server-Driven UI Dynamic Section Builder
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildDynamicSections({
    required BuildContext context,
    required List<StorefrontSectionModel> sections,
    required List<CategoryModel> categories,
    required List<BannerModel> banners,
    required List<ProductModel> allProducts,
    required List<AdModel> ads,
    required List<BrandModel> brands,
    required List<ProductCollectionModel> collections,
    required dynamic currentUser,
  }) {
    final List<Widget> slivers = [];

    for (final section in sections) {
      if (!section.isEnabled || !section.isCurrentlyScheduledActive) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: StorefrontSectionRenderer(
            section: section,
            allProducts: allProducts,
            categories: categories,
            banners: banners,
            ads: ads,
            brands: brands,
            collections: collections,
            loggedImpressions: _loggedImpressions,
            currentUserId: currentUser != null ? (currentUser.uid as String?) : null,
          ),
        ),
      );
    }

    return slivers;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: Deliver To + Brand Logo + Search with Filter
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildReferenceHeader({
    required BuildContext context,
    required String addressText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Location (Left) & Brand Logo (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Deliver to location (Expanded so it safely adapts and never pushes the logo out)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/checkout/address'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Royal Blue Location Pin
                      const Icon(
                        Icons.location_on_rounded,
                        size: 24,
                        color: AppColors.royalBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deliver to',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    addressText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.royalBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Maruti Stationery Logo (Right) — fixed width and anchored safely
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20173A9B),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Maruti\nStationery',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Stationery & Supplies',
                        style: GoogleFonts.poppins(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Box with Enhanced Soft Shadow and Blue Filter Icon
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/search'),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : const Color(0x28000000), // clearly visible drop shadow
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0.8,
                  ),
                  BoxShadow(
                    color: isDark ? Colors.transparent : const Color(0x0E173A9B), // subtle ambient blue
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.royalBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSearchHint(
                      hints: const [
                        'pens & pencils',
                        'spiral notebooks',
                        'highlighters & markers',
                        'doms color pencils',
                        'classmate books',
                        'sticky notes',
                        'geometry boxes',
                        'fevicol & glue sticks',
                        'art & craft supplies',
                        'files & folders',
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.royalBlue,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Skeletons
  Widget _buildBannerSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildCategorySkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          5,
          (i) => Container(
            width: 64,
            height: 94,
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGridSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. REFERENCE CATEGORIES (Tall Pastel Pill Cards matching Reference Image)
// ─────────────────────────────────────────────────────────────────────────────
class _ReferenceCategoryPills extends StatelessWidget {
  final List<CategoryModel> categories;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ReferenceCategoryPills({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  static const List<Map<String, dynamic>> _pastelThemes = [
    {
      'bg': Color(0xFFC7DCF8),
      'iconColor': Color(0xFF1A38C9),
      'icon': Icons.edit_rounded
    },
    {
      'bg': Color(0xFFFBE4A9),
      'iconColor': Color(0xFF1A38C9),
      'icon': Icons.menu_book_rounded
    },
    {
      'bg': Color(0xFFF4EFE6),
      'iconColor': Color(0xFF475569),
      'icon': Icons.crop_portrait_rounded
    },
    {
      'bg': Color(0xFFEBF2FC),
      'iconColor': Color(0xFF1A38C9),
      'icon': Icons.folder_rounded
    },
    {
      'bg': Color(0xFFFAF3E3),
      'iconColor': Color(0xFF1A38C9),
      'icon': Icons.border_color_rounded
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/categories'),
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 98,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final bool isAllSelected = selectedId == 'all';
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCategoryPill(
                    title: 'All',
                    bgColor: AppColors.primary,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    icon: Icons.grid_view_rounded,
                    onTap: () => onSelect('all'),
                    hasShadow: isAllSelected,
                  ),
                );
              }

              final cat = categories[index - 1];
              final theme = _pastelThemes[(index - 1) % _pastelThemes.length];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildCategoryPill(
                  title: cat.name,
                  bgColor: theme['bg'] as Color,
                  iconColor: theme['iconColor'] as Color,
                  textColor: AppColors.textPrimary,
                  icon: theme['icon'] as IconData,
                  imageUrl: cat.image.isNotEmpty ? cat.image : null,
                  onTap: () => onSelect(cat.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill({
    required String title,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
    String? imageUrl,
    required VoidCallback onTap,
    bool hasShadow = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 68,
        height: 96,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: hasShadow
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : const Color(0x28000000), // clearly visible category drop shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0.8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null)
              SizedBox(
                width: 32,
                height: 32,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Icon(icon, size: 26, color: iconColor),
                  errorWidget: (_, __, ___) => Icon(icon, size: 26, color: iconColor),
                ),
              )
            else
              Icon(icon, size: 26, color: iconColor),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. REFERENCE BANNER SECTION (Royal Blue, 20px Radius, Orange "Shop Now ->")
// ─────────────────────────────────────────────────────────────────────────────
class _ReferenceBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  const _ReferenceBannerCarousel({required this.banners});

  @override
  State<_ReferenceBannerCarousel> createState() => _ReferenceBannerCarouselState();
}

class _ReferenceBannerCarouselState extends State<_ReferenceBannerCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || widget.banners.isEmpty) return;
      final next = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onBannerTap(BannerModel banner) {
    if (banner.targetProductId != null && banner.targetProductId!.isNotEmpty) {
      context.push('/catalog/product/${banner.targetProductId}');
    } else if (banner.targetCategoryId != null && banner.targetCategoryId!.isNotEmpty) {
      context.push('/catalog?categoryId=${banner.targetCategoryId}');
    } else if (banner.tag != null && banner.tag!.isNotEmpty) {
      final title = Uri.encodeComponent(banner.title ?? banner.tag!);
      context.push('/banner-products?tag=${banner.tag}&title=$title');
    } else {
      context.push('/catalog');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return _ReferenceDefaultBanner(onTap: () => context.push('/catalog'));
    }

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () => _onBannerTap(banner),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x30000000), // distinct ground drop shadow
                          blurRadius: 14,
                          offset: Offset(0, 6),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Color(0x40173A9B), // vibrant royal blue ambient shadow
                          blurRadius: 20,
                          offset: Offset(0, 8),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.royalBlue,
                            ),
                            errorWidget: (_, __, ___) => _ReferenceDefaultBannerContent(
                              title: banner.title ?? 'Back to School Essentials',
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Shop Now',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentIndex == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentIndex == i
                      ? AppColors.primary
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReferenceDefaultBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ReferenceDefaultBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 165,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000), // distinct ground drop shadow
                blurRadius: 14,
                offset: Offset(0, 6),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Color(0x40173A9B), // vibrant royal blue ambient shadow
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const _ReferenceDefaultBannerContent(
              title: 'Back to School Essentials',
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceDefaultBannerContent extends StatelessWidget {
  final String title;
  const _ReferenceDefaultBannerContent({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF173A9B),
            Color(0xFF1E42BA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'UP TO 40% OFF',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'UP TO\nOFF',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shop Now',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 75,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. REFERENCE SHOP BY USE CASE (Pens Essentials & Book Essentials)
// ─────────────────────────────────────────────────────────────────────────────
class _ReferenceUseCaseSection extends StatelessWidget {
  final List<CategoryModel> categories;
  const _ReferenceUseCaseSection({required this.categories});

  void _navigateToCategory(BuildContext context, String keyword) {
    final match = categories.where(
      (c) => c.name.toLowerCase().contains(keyword.toLowerCase()),
    );
    if (match.isNotEmpty) {
      context.push('/catalog?categoryId=${match.first.id}');
    } else {
      context.push('/catalog');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop by Use Case',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/categories'),
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              // Card 1: Pens Essentials
              Expanded(
                child: _buildUseCaseCard(
                  context: context,
                  title: 'Pens Essentials',
                  subtitle: 'Daily writing essentials',
                  imageUrl:
                      'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400&q=80',
                  icon: Icons.edit_rounded,
                  onTap: () => _navigateToCategory(context, 'pen'),
                ),
              ),
              const SizedBox(width: 14),
              // Card 2: Book Essentials
              Expanded(
                child: _buildUseCaseCard(
                  context: context,
                  title: 'Book Essentials',
                  subtitle: 'Notebooks & study materials',
                  imageUrl:
                      'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80',
                  icon: Icons.menu_book_rounded,
                  onTap: () => _navigateToCategory(context, 'book'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUseCaseCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imageUrl,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000), // clearly visible use-case drop shadow
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: 0.8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceWarm,
                    child: Center(
                      child: Icon(icon, color: AppColors.royalBlue, size: 32),
                    ),
                  ),
                  errorWidget: (context, url, err) => Center(
                    child: Icon(icon, color: AppColors.royalBlue, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Subtitle & Arrow Button Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Orange Arrow Button matching Screen 1
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DYNAMIC PRODUCT SECTION (GRID OR HORIZONTAL CAROUSEL)
// ─────────────────────────────────────────────────────────────────────────────
class _DynamicProductSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ProductModel> products;
  final String displayStyle; // 'grid', 'horizontal'
  final String? categoryId;
  final int limit;

  const _DynamicProductSection({
    required this.title,
    this.subtitle,
    required this.products,
    this.displayStyle = 'grid',
    this.categoryId,
    this.limit = 8,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = products;
    if (categoryId != null && categoryId!.isNotEmpty && categoryId != 'all') {
      filtered = filtered.where((p) => p.categoryId == categoryId).toList();
    }
    if (filtered.isEmpty) return const SizedBox.shrink();

    final displayList = filtered.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (categoryId != null && categoryId!.isNotEmpty && categoryId != 'all') {
                    context.push('/catalog?categoryId=$categoryId');
                  } else {
                    context.push('/catalog');
                  }
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (displayStyle == 'horizontal')
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 175,
                  child: ProductCard(product: displayList[index]),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = (constraints.maxWidth - 14) / 2;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: displayList.map((product) {
                    return SizedBox(
                      width: cardWidth,
                      height: 275,
                      child: ProductCard(product: product),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. REFERENCE BUY AGAIN SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ReferenceBuyAgainSection extends ConsumerWidget {
  final String userId;
  final AsyncValue<List<ProductModel>> allProductsAsync;

  const _ReferenceBuyAgainSection({
    required this.userId,
    required this.allProductsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userOrdersAsync = ref.watch(watchUserOrdersProvider(userId));

    return userOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();

        return allProductsAsync.when(
          data: (allProducts) {
            final List<ProductModel> boughtProducts = [];
            final Set<String> seenIds = {};

            for (final order in orders) {
              for (final item in order.items) {
                if (!seenIds.contains(item.productId)) {
                  seenIds.add(item.productId);
                  final match =
                      allProducts.where((p) => p.id == item.productId);
                  if (match.isNotEmpty) {
                    boughtProducts.add(match.first);
                  }
                }
              }
            }

            if (boughtProducts.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Buy Again',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/orders'),
                        child: Text(
                          'See all',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: boughtProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 168,
                        child: ProductCard(product: boughtProducts[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. REFERENCE SPONSORED PARTNER ADS
// ─────────────────────────────────────────────────────────────────────────────
class _ReferenceSponsoredSection extends ConsumerWidget {
  final List<AdModel> ads;
  final Set<String> loggedImpressions;

  const _ReferenceSponsoredSection({
    required this.ads,
    required this.loggedImpressions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ads.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Partners',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AD',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 155,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final ad = ads[index];
              return GestureDetector(
                onTap: () {
                  logAdClick(ad.id);
                  if (ad.hasCta) {
                    switch (ad.ctaType) {
                      case AdCtaType.product:
                        context.push('/catalog/product/${ad.ctaValue}');
                        break;
                      case AdCtaType.category:
                        context.go('/catalog?categoryId=${ad.ctaValue}');
                        break;
                      case AdCtaType.collection:
                        final title = Uri.encodeComponent(ad.ctaLabel);
                        context.push('/banner-products?tag=${ad.ctaValue}&title=$title');
                        break;
                      case AdCtaType.url:
                        launchUrl(Uri.parse(ad.ctaValue), mode: LaunchMode.externalApplication);
                        break;
                      case AdCtaType.none:
                        break;
                    }
                  }
                },
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28000000), // clearly visible ad drop shadow
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        spreadRadius: 0.8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: ad.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceWarm,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceWarm,
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: AppColors.textHint,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
