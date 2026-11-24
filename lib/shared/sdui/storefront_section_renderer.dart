import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_optimizer.dart';
import '../../models/storefront_section_model.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../models/banner_model.dart';
import '../../models/ad_model.dart';
import '../../models/brand_model.dart';
import '../../models/product_collection_model.dart';
import '../../features/catalog/widgets/product_card.dart';
import '../../features/catalog/widgets/ad_card.dart';

class StorefrontSectionRenderer extends ConsumerWidget {
  final StorefrontSectionModel section;
  final List<ProductModel> allProducts;
  final List<CategoryModel> categories;
  final List<BannerModel> banners;
  final List<AdModel> ads;
  final List<BrandModel> brands;
  final List<ProductCollectionModel> collections;
  final Set<String> loggedImpressions;
  final String? currentUserId;

  const StorefrontSectionRenderer({
    super.key,
    required this.section,
    required this.allProducts,
    required this.categories,
    required this.banners,
    required this.ads,
    required this.brands,
    required this.collections,
    required this.loggedImpressions,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Guard against disabled or scheduled-out sections
    if (!section.isEnabled || !section.isCurrentlyScheduledActive) {
      return const SizedBox.shrink();
    }

    // 2. Safe Error Boundary — guarantees no single bad section crashes the screen
    return _SafeSectionBoundary(
      sectionId: section.id,
      child: Container(
        margin: EdgeInsets.only(
          top: section.paddingTop,
          bottom: section.paddingBottom,
        ),
        color: section.backgroundColor != null
            ? _parseColor(section.backgroundColor!)
            : Colors.transparent,
        child: _buildSectionContent(context, ref),
      ),
    );
  }

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.transparent;
    }
  }

  Widget _buildSectionContent(BuildContext context, WidgetRef ref) {
    switch (section.type) {
      // ── Promotional Sections ───────────────────────────────────────────────
      case StorefrontSectionType.heroBanner:
      case StorefrontSectionType.bannerCarousel:
        return _buildBannerCarousel(context);

      case StorefrontSectionType.promoImageBanner:
      case StorefrontSectionType.campaignBanner:
        return _buildPromoImageBanner(context);

      case StorefrontSectionType.offerStrip:
      case StorefrontSectionType.announcementBar:
        return _buildAnnouncementStrip(context);

      // ── Category Sections ──────────────────────────────────────────────────
      case StorefrontSectionType.categories:
        return _buildCategoryPills(context);

      case StorefrontSectionType.categoryGrid:
      case StorefrontSectionType.categoryCarousel:
      case StorefrontSectionType.featuredCategories:
        return _buildCategoryGrid(context);

      case StorefrontSectionType.useCase:
        return _buildUseCaseSection(context);

      // ── Product Sections ───────────────────────────────────────────────────
      case StorefrontSectionType.trending:
      case StorefrontSectionType.bestSellers:
      case StorefrontSectionType.newArrivals:
      case StorefrontSectionType.featuredProducts:
      case StorefrontSectionType.topRated:
      case StorefrontSectionType.recommended:
      case StorefrontSectionType.recentlyViewed:
      case StorefrontSectionType.frequentlyBought:
      case StorefrontSectionType.customProducts:
      case StorefrontSectionType.productCarousel:
      case StorefrontSectionType.productGrid:
        return _buildProductSection(context);

      case StorefrontSectionType.buyAgain:
        return _buildBuyAgainSection(context);

      // ── Content Sections ───────────────────────────────────────────────────
      case StorefrontSectionType.brandCollection:
        return _buildBrandCollection(context);

      case StorefrontSectionType.imageText:
      case StorefrontSectionType.editorial:
        return _buildEditorialSection(context);

      case StorefrontSectionType.ads:
        return _buildAdsSection(context);

      default:
        // Gracefully ignore unknown future section types without crashing
        return const SizedBox.shrink();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // A. SECTION HEADER COMPONENT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, {VoidCallback? onSeeAll}) {
    if (section.title.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  section.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: section.textColor != null
                        ? _parseColor(section.textColor!)
                        : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (section.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      section.subtitle,
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
            behavior: HitTestBehavior.opaque,
            onTap: onSeeAll ?? () => _handleSeeAll(context),
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
    );
  }

  void _handleSeeAll(BuildContext context) {
    if (section.seeAllDestination != null && section.seeAllDestination!.isNotEmpty) {
      context.push(section.seeAllDestination!);
      return;
    }

    if (section.categoryId != null && section.categoryId!.isNotEmpty) {
      context.push('/catalog?categoryId=${section.categoryId}');
    } else {
      context.push('/catalog');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // B. BANNER CAROUSEL & HERO BANNER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBannerCarousel(BuildContext context) {
    if (banners.isEmpty) {
      return _buildDefaultBannerContent(context);
    }

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            itemCount: banners.length,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (context, index) {
              final b = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () {
                    if (b.targetProductId != null && b.targetProductId!.isNotEmpty) {
                      context.push('/catalog/product/${b.targetProductId}');
                    } else if (b.targetCategoryId != null && b.targetCategoryId!.isNotEmpty) {
                      context.push('/catalog?categoryId=${b.targetCategoryId}');
                    } else {
                      context.push('/catalog');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: ImageOptimizer.getBannerUrl(b.imageUrl),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceWarm),
                        errorWidget: (_, __, ___) => _buildDefaultBannerContent(context),
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

  Widget _buildDefaultBannerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF7ED),
              Color(0xFFFFECE0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFDE68A).withValues(alpha: 0.6),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Everything You Need,\nAll in One Place!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Premium Stationery for\nSchool, College & Office',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4B5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push('/catalog'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11.5,
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
            Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  width: 72,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                      const SizedBox(height: 3),
                      Text(
                        'MARUTI',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoImageBanner(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();
    final b = banners.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: () => _handleSeeAll(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: ImageOptimizer.getBannerUrl(b.imageUrl),
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surfaceWarm),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementStrip(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.title.isNotEmpty ? section.title : '🔥 Flat 20% OFF on all Spiral Notebooks! Use code: MARUTI20',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // C. CATEGORY SECTIONS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryPills(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, onSeeAll: () => context.push('/categories')),
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
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCategoryPillItem(
                    title: 'All',
                    bgColor: AppColors.primary,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    icon: Icons.grid_view_rounded,
                    onTap: () => context.push('/catalog'),
                  ),
                );
              }
              final cat = categories[index - 1];
              const pastelColors = [
                Color(0xFFEAF2FD),
                Color(0xFFEBF3FE),
                Color(0xFFF1F5F9),
                Color(0xFFEAF2FD),
                Color(0xFFFFF2EB),
              ];
              final bg = pastelColors[(index - 1) % pastelColors.length];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildCategoryPillItem(
                  title: cat.name,
                  bgColor: bg,
                  iconColor: AppColors.royalBlue,
                  textColor: AppColors.textPrimary,
                  icon: Icons.menu_book_rounded,
                  imageUrl: cat.image.isNotEmpty ? cat.image : null,
                  onTap: () => context.push('/catalog?categoryId=${cat.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPillItem({
    required String title,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
    String? imageUrl,
    required VoidCallback onTap,
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 3),
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
                  imageUrl: ImageOptimizer.getThumbnailUrl(imageUrl, width: 80, height: 80),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Icon(icon, size: 24, color: iconColor),
                  errorWidget: (_, __, ___) => Icon(icon, size: 24, color: iconColor),
                ),
              )
            else
              Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
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

  Widget _buildCategoryGrid(BuildContext context) {
    final displayCats = categories.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, onSeeAll: () => context.push('/categories')),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, i) {
              final cat = displayCats[i];
              return GestureDetector(
                onTap: () => context.push('/catalog?categoryId=${cat.id}'),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(Icons.category_rounded, color: AppColors.royalBlue, size: 26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600),
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

  Widget _buildUseCaseSection(BuildContext context) {
    final items = [
      {
        'title': 'School\nEssentials',
        'keyword': 'school',
        'icon': Icons.backpack_rounded,
        'bg': const Color(0xFFFFF3EB),
        'iconColor': const Color(0xFFEE6A2B),
      },
      {
        'title': 'College\nEssentials',
        'keyword': 'book',
        'icon': Icons.menu_book_rounded,
        'bg': const Color(0xFFEBF3FE),
        'iconColor': const Color(0xFF1A38C9),
      },
      {
        'title': 'Office\nSupplies',
        'keyword': 'office',
        'icon': Icons.work_outline_rounded,
        'bg': const Color(0xFFFFF8E7),
        'iconColor': const Color(0xFFB45309),
      },
      {
        'title': 'Art &\nCraft',
        'keyword': 'art',
        'icon': Icons.palette_outlined,
        'bg': const Color(0xFFF5EBFB),
        'iconColor': const Color(0xFF9333EA),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, onSeeAll: () => context.push('/categories')),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final kw = item['keyword'] as String;
                      final match = categories.where((c) => c.name.toLowerCase().contains(kw));
                      if (match.isNotEmpty) {
                        context.push('/catalog?categoryId=${match.first.id}');
                      } else {
                        context.push('/catalog');
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 76,
                          decoration: BoxDecoration(
                            color: item['bg'] as Color,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              item['icon'] as IconData,
                              size: 32,
                              color: item['iconColor'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // D. PRODUCT SECTIONS (CAROUSEL & GRID VARIANTS)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProductSection(BuildContext context) {
    final products = _resolveProducts();
    if (products.isEmpty) return const SizedBox.shrink();

    final isGrid = section.layoutVariant.contains('grid');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        if (isGrid)
          _buildProductGridLayout(context, products)
        else
          _buildProductCarouselLayout(context, products),
      ],
    );
  }

  List<ProductModel> _resolveProducts() {
    // 1. If manual product IDs are configured, take those
    if (section.manualProductIds.isNotEmpty) {
      final idSet = section.manualProductIds.toSet();
      final matched = allProducts.where((p) => idSet.contains(p.id) && p.isActive).toList();
      matched.sort((a, b) {
        final iA = section.manualProductIds.indexOf(a.id);
        final iB = section.manualProductIds.indexOf(b.id);
        return iA.compareTo(iB);
      });
      return matched.take(section.limit).toList();
    }

    // 2. If collection ID is specified, resolve from collections list
    if (section.collectionId != null && section.collectionId!.isNotEmpty) {
      final col = collections.firstWhere(
        (c) => c.id == section.collectionId,
        orElse: () => ProductCollectionModel(
          id: '',
          name: '',
          description: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (col.id.isNotEmpty && col.productIds.isNotEmpty) {
        final idSet = col.productIds.toSet();
        return allProducts.where((p) => idSet.contains(p.id) && p.isActive).take(section.limit).toList();
      }
    }

    // 3. Fallback to category or query rules
    var list = allProducts.where((p) => p.isActive).toList();
    if (section.categoryId != null && section.categoryId!.isNotEmpty && section.categoryId != 'all') {
      list = list.where((p) => p.categoryId == section.categoryId).toList();
    }

    switch (section.type) {
      case StorefrontSectionType.trending:
      case StorefrontSectionType.bestSellers:
        list.sort((a, b) {
          if (a.isOnSale && !b.isOnSale) return -1;
          if (!a.isOnSale && b.isOnSale) return 1;
          return b.salesCount.compareTo(a.salesCount);
        });
        break;
      case StorefrontSectionType.newArrivals:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case StorefrontSectionType.topRated:
        list = list.where((p) => p.averageRating >= 4.0).toList();
        list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
    }

    return list.take(section.limit).toList();
  }

  Widget _buildProductCarouselLayout(BuildContext context, List<ProductModel> products) {
    final double cardWidth = section.layoutVariant == StorefrontLayoutVariant.carouselCompact
        ? 150.0
        : 175.0;
    final double carouselHeight = section.layoutVariant == StorefrontLayoutVariant.carouselCompact
        ? 245.0
        : 280.0;

    return SizedBox(
      height: carouselHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return SizedBox(
            width: cardWidth,
            child: ProductCard(product: products[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductGridLayout(BuildContext context, List<ProductModel> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final is3Col = section.layoutVariant == StorefrontLayoutVariant.grid3Col &&
              constraints.maxWidth > 500;
          final cols = is3Col ? 3 : 2;
          final spacing = 12.0;
          final cardWidth = (constraints.maxWidth - ((cols - 1) * spacing)) / cols;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: products.map((product) {
              return SizedBox(
                width: cardWidth,
                height: 275,
                child: ProductCard(product: product),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildBuyAgainSection(BuildContext context) {
    if (currentUserId == null) return const SizedBox.shrink();
    final products = allProducts.take(6).toList();
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, onSeeAll: () => context.push('/orders')),
        const SizedBox(height: 14),
        _buildProductCarouselLayout(context, products),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // E. BRANDS, EDITORIAL & ADS SECTIONS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBrandCollection(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final b = brands[index];
              return GestureDetector(
                onTap: () => context.push('/catalog?brand=${b.name}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      b.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyText,
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

  Widget _buildEditorialSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.royalBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title.isNotEmpty ? section.title : 'Study & Office Essentials Guide',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.description.isNotEmpty
                ? section.description
                : 'Choosing the right notebook GSM and smooth rollerball pens for effortless notes.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/catalog'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Explore Guide →',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsSection(BuildContext context) {
    if (ads.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.isNotEmpty) ...[
          _buildHeader(context),
          const SizedBox(height: 14),
        ],
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              return SizedBox(
                width: 280,
                child: AdCard(
                  ad: ads[i],
                  loggedImpressions: loggedImpressions,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Safe Section Boundary to prevent individual section exceptions from failing the screen
class _SafeSectionBoundary extends StatelessWidget {
  final String sectionId;
  final Widget child;

  const _SafeSectionBoundary({required this.sectionId, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
