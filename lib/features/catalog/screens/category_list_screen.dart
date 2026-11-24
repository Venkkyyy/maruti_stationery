import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/banner_provider.dart';
import '../../../providers/ads_provider.dart';
import '../../../models/ad_model.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
    final bannersAsync = ref.watch(bannerProvider);
    final adsAsync = ref.watch(activeAdsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(activeCategoriesStreamProvider);
            ref.invalidate(bannerProvider);
            ref.invalidate(activeAdsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── 1. SCREEN HEADER (Back + "Categories" + Search) ──────────
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ── 2. PROMOTIONAL BANNER ────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildPromotionalBanner(context, bannersAsync),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── 3. CATEGORIES GRID (2 Columns, Ivory Cards, Orange Arrow)
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No categories found',
                            style: GoogleFonts.poppins(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.96,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          return _buildCategoryCard(context, category, isDark);
                        },
                        childCount: categories.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: _buildCategoryGridSkeleton(context),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Failed to load categories',
                        style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── 4. ADDITIONAL SECTION: FEATURED SPOTLIGHT ────────────────
              SliverToBoxAdapter(
                child: adsAsync.when(
                  data: (ads) => _buildPromotionalSection(context, ads.firstOrNull),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => _buildPromotionalSection(context, null),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: Minimal Back Icon + "Categories" Title + Search Icon
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                    context.go('/home');
                  }
                },
              ),
              const SizedBox(width: 2),
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          IconButton(
            splashRadius: 22,
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Promotional Banner: "Everything you need, all in one place"
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPromotionalBanner(
      BuildContext context, AsyncValue bannersAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDCEBFE), // Soft powder sky blue
            Color(0xFFEBF3FD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC7DCF8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1A38C9),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background subtle radial circle
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),

            // Content Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  // Text Details
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Everything you need,\nall in one place',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A), // Deep Royal Blue
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Explore our wide range of stationery and school supplies.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Stationery Illustration / Icon Box
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F1A38C9),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 14,
                              right: 20,
                              child: Icon(
                                Icons.edit_rounded,
                                size: 32,
                                color: AppColors.royalBlue.withValues(alpha: 0.85),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              left: 18,
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 38,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 18,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFD97706),
                                ),
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
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category Card: Ivory Card with 20px Radius & Orange Arrow Button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryCard(
      BuildContext context, CategoryModel category, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.push('/catalog?categoryId=${category.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.border,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Category Image/Illustration
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF242424) : AppColors.surfaceWarm,
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: _buildCategoryImage(category),
                  ),
                ),
              ),

              // Bottom Category Name + Orange Arrow
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Small Orange Arrow Button matching reference
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, // #EE6A2B
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x30EE6A2B),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
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

  // Helper to load category image or relevant contextual icon
  Widget _buildCategoryImage(CategoryModel category) {
    if (category.image.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: category.image,
        fit: BoxFit.contain,
        memCacheWidth: 280,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, err) => _buildFallbackCategoryIcon(category.name),
      );
    }
    return _buildFallbackCategoryIcon(category.name);
  }

  Widget _buildFallbackCategoryIcon(String name) {
    final lower = name.toLowerCase();
    IconData iconData = Icons.category_rounded;
    Color iconColor = AppColors.royalBlue;

    if (lower.contains('pen') || lower.contains('writing') || lower.contains('pencil')) {
      iconData = Icons.edit_rounded;
      iconColor = const Color(0xFF1A38C9);
    } else if (lower.contains('notebook') || lower.contains('pad')) {
      iconData = Icons.menu_book_rounded;
      iconColor = const Color(0xFF0D9488);
    } else if (lower.contains('book')) {
      iconData = Icons.auto_stories_rounded;
      iconColor = const Color(0xFFD97706);
    } else if (lower.contains('art') || lower.contains('craft') || lower.contains('color')) {
      iconData = Icons.palette_rounded;
      iconColor = const Color(0xFFE11D48);
    } else if (lower.contains('file') || lower.contains('folder')) {
      iconData = Icons.folder_rounded;
      iconColor = const Color(0xFF2563EB);
    } else if (lower.contains('eraser') || lower.contains('correction')) {
      iconData = Icons.crop_portrait_rounded;
      iconColor = const Color(0xFF475569);
    } else if (lower.contains('office') || lower.contains('desk') || lower.contains('stapler')) {
      iconData = Icons.inventory_2_rounded;
      iconColor = const Color(0xFF0F172A);
    } else if (lower.contains('geometry') || lower.contains('drawing') || lower.contains('scale')) {
      iconData = Icons.square_foot_rounded;
      iconColor = const Color(0xFF7C3AED);
    } else if (lower.contains('bag') || lower.contains('school')) {
      iconData = Icons.backpack_rounded;
      iconColor = const Color(0xFFEA580C);
    } else if (lower.contains('sharpener')) {
      iconData = Icons.border_color_rounded;
      iconColor = const Color(0xFFCA8A04);
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 28,
        color: iconColor,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Additional Section: Promotional Spotlight ("Premium Quality Stationery")
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPromotionalSection(BuildContext context, AdModel? ad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Graphic container
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(16),
            ),
            child: (ad != null && ad.thumbnailUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: ad.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, err) => const Icon(
                        Icons.verified_rounded,
                        color: AppColors.royalBlue,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
          ),

          const SizedBox(width: 14),

          // Details & Explore Now button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad?.ctaLabel.isNotEmpty == true
                      ? 'Featured Collection'
                      : 'Premium Quality Stationery',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Curated school & office supplies delivered right to your doorstep.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/catalog'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Now',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Skeleton Loader for Categories Grid
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryGridSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.96,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
