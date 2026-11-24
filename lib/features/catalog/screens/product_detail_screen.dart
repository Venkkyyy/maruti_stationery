import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../models/product_model.dart';
import '../../../models/review_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImage = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _qty = 1;
  Map<String, String> _selectedVariations = {};

  void _addToBag(ProductModel product) async {
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(product, _qty, selectedVariations: _selectedVariations);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added $_qty item${_qty > 1 ? 's' : ''} to cart',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _buyNow(ProductModel product) async {
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(product, _qty, selectedVariations: _selectedVariations);
      if (mounted) {
        context.push('/checkout/address');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareProduct(ProductModel product) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Check out ${product.name} on Maruti Stationery: ${AppFormatters.formatPrice(product.price)}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Product details copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.inkDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _parseColor(String colorName) {
    final name = colorName.toLowerCase().trim();
    if (name.contains('blue') || name.contains('navy')) {
      return const Color(0xFF1A38C9);
    }
    if (name.contains('green') || name.contains('emerald')) {
      return const Color(0xFF16A34A);
    }
    if (name.contains('pink') || name.contains('rose')) {
      return const Color(0xFFEC4899);
    }
    if (name.contains('purple') || name.contains('violet')) {
      return const Color(0xFF8B5CF6);
    }
    if (name.contains('yellow') || name.contains('tan') || name.contains('gold')) {
      return const Color(0xFFF59E0B);
    }
    if (name.contains('red') || name.contains('crimson')) {
      return const Color(0xFFEF4444);
    }
    if (name.contains('orange')) {
      return const Color(0xFFEE6A2B);
    }
    if (name.contains('black')) {
      return const Color(0xFF1E293B);
    }
    if (name.contains('white')) {
      return const Color(0xFFF8FAFC);
    }
    if (name.contains('grey') || name.contains('gray')) {
      return const Color(0xFF94A3B8);
    }
    if (name.contains('teal') || name.contains('cyan')) {
      return const Color(0xFF0D9488);
    }
    return AppColors.royalBlue;
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(watchProductProvider(widget.productId));
    final liveReviews = ref.watch(productReviewsProvider(widget.productId)).value ?? [];

    return productAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _buildCircularButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Failed to load product details.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _buildCircularButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            body: const Center(
              child: Text(
                'Product not found.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final wishlistAsync = ref.watch(watchWishlistProvider);
        final isWishlisted =
            wishlistAsync.value?.any((p) => p.id == product.id) ?? false;

        final liveCount = liveReviews.isNotEmpty ? liveReviews.length : product.reviewCount;
        final liveAvg = liveReviews.isNotEmpty
            ? (liveReviews.fold<double>(0.0, (acc, r) => acc + r.rating) / liveReviews.length)
            : product.averageRating;

        // Auto-select initial variations
        if (_selectedVariations.isEmpty && product.variations.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                product.variations.forEach((k, v) {
                  if (v.isNotEmpty) _selectedVariations[k] = v.first;
                });
              });
            }
          });
        }

        final cartAsync = ref.watch(cartProvider);
        final isInCart =
            cartAsync.value?.any((item) {
              if (item.productId != product.id) return false;
              if (product.variations.isEmpty) return true;
              for (final key in _selectedVariations.keys) {
                if (item.selectedVariations[key] != _selectedVariations[key]) {
                  return false;
                }
              }
              return true;
            }) ??
            false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Scrollable Content
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Sliver Header / Image Gallery
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Navigation Row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back Button
                                  _buildCircularButton(
                                    icon: Icons.arrow_back_rounded,
                                    onTap: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/home');
                                      }
                                    },
                                  ),
                                  // Actions: Wishlist + Share
                                  Row(
                                    children: [
                                      _buildCircularButton(
                                        icon: isWishlisted
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        iconColor: isWishlisted
                                            ? AppColors.error
                                            : AppColors.inkDark,
                                        onTap: () {
                                          if (isWishlisted) {
                                            ref
                                                .read(
                                                  wishlistProvider.notifier,
                                                )
                                                .remove(product.id);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Removed from Wishlist',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          } else {
                                            ref
                                                .read(
                                                  wishlistProvider.notifier,
                                                )
                                                .add(product);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Added to Wishlist!',
                                                ),
                                                backgroundColor:
                                                    AppColors.primary,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      _buildCircularButton(
                                        icon: Icons.share_outlined,
                                        iconColor: AppColors.inkDark,
                                        onTap: () => _shareProduct(product),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Main Hero Image Container
                            _buildHeroGallery(product),

                            // Thumbnails Row (if multiple images)
                            if (product.images.length > 1)
                              _buildThumbnailsRow(product),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Product Details Surface
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkDark,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Ratings & In-Stock Status Row
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Rating + Review Count
                                InkWell(
                                  onTap: () => context.push(
                                    '/catalog/product/${product.id}/reviews',
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        if (liveCount > 0 && liveAvg > 0) ...[
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF59E0B),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            liveAvg.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.inkDark,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${product.reviewCount} ${product.reviewCount == 1 ? 'review' : 'reviews'})',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ] else ...[
                                          const Icon(
                                            Icons.star_border_rounded,
                                            color: AppColors.textHint,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'No ratings yet',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: AppColors.textHint,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Stock Pill Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product.isInStock
                                        ? const Color(0xFFEAF8EF)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: product.isInStock
                                          ? const Color(0xFFD1F2D9)
                                          : const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        product.isInStock
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        size: 13,
                                        color: product.isInStock
                                            ? const Color(0xFF1E9A4B)
                                            : AppColors.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.isInStock
                                            ? (product.stock <= 5
                                                ? '${product.stock} left in stock'
                                                : 'In Stock')
                                            : 'Out of Stock',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: product.isInStock
                                              ? const Color(0xFF1E9A4B)
                                              : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Price Row (Bold Price + MRP + Discount Pill)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  AppFormatters.formatPrice(product.price),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.inkDark,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (product.isOnSale) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    'MRP ${AppFormatters.formatPrice(product.mrp)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textHint,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1EB),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFCD8C6),
                                      ),
                                    ),
                                    child: Text(
                                      '${product.discountPercent}% OFF',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Description Section
                            if (product.description.isNotEmpty) ...[
                              Text(
                                product.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Variations (Colors & Options)
                            if (product.variations.isNotEmpty) ...[
                              _buildVariations(product),
                              const SizedBox(height: 24),
                            ],

                            // Product Specifications Card
                            if (product.specifications.isNotEmpty) ...[
                              _buildSpecificationsCard(product),
                              const SizedBox(height: 24),
                            ],

                            // Product Highlights
                            if (product.highlights.isNotEmpty) ...[
                              _buildHighlightsCard(product),
                              const SizedBox(height: 24),
                            ],

                            // Brand Information Tile
                            _buildBrandTile(product),
                            const SizedBox(height: 16),

                            // Return & Replacement Policy
                            _buildPolicyTile(product),
                            const SizedBox(height: 24),

                            // Reviews Summary & View Reviews Button
                            _buildReviewsAction(product),
                            const SizedBox(height: 32),

                            // Suggested / Related Products
                            _buildSuggestedProducts(product),
                            const SizedBox(height: 28),

                            // Top Products / New Arrivals
                            _buildTopProducts(product),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Fixed Bottom Purchase Bar
              _buildBottomPurchaseBar(product, isInCart),
            ],
          ),
        );
      },
    );
  }

  // ── Top Bar Circular Buttons ──────────────────────────────────────
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppColors.inkDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  // ── Hero Gallery Container ─────────────────────────────────────────
  Widget _buildHeroGallery(ProductModel product) {
    final images = product.images;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (images.isNotEmpty)
                CarouselSlider(
                  carouselController: _carouselController,
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: images.length > 1,
                    onPageChanged: (index, reason) {
                      setState(() => _selectedImage = index);
                    },
                  ),
                  items: images.map((img) {
                    return Center(
                      child: CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.contain,
                        memCacheWidth: 700,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceWarm,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, err) => Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 80,
                            color: AppColors.textHint.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 90,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                ),

              // Page Indicators (if multiple)
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _selectedImage == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _selectedImage == i
                              ? AppColors.primary
                              : AppColors.textHint.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Thumbnails Row ────────────────────────────────────────────────
  Widget _buildThumbnailsRow(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: product.images.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final isSelected = _selectedImage == i;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedImage = i);
                _carouselController.animateToPage(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.royalBlue
                        : AppColors.border.withValues(alpha: 0.8),
                    width: isSelected ? 2.2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.royalBlue.withValues(alpha: 0.15)
                          : const Color(0x06000000),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: product.images[i],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceWarm,
                    ),
                    errorWidget: (context, url, err) => const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Product Variations (Colors & Chips) ───────────────────────────
  Widget _buildVariations(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: product.variations.entries
          .where((e) => e.value.isNotEmpty)
          .map((entry) {
            final isColor = entry.key.toLowerCase().contains('color');
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkDark,
                        ),
                      ),
                      if (_selectedVariations[entry.key] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          ': ${_selectedVariations[entry.key]}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (isColor)
                    // Circular Color Swatches matching Screen 4 in mockup
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: entry.value.map((colorName) {
                        final isSelected =
                            _selectedVariations[entry.key] == colorName;
                        final swatchColor = _parseColor(colorName);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedVariations[entry.key] = colorName;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.inkDark
                                    : Colors.white,
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    )
                  else
                    // Selectable Rounded Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((val) {
                        final isSelected =
                            _selectedVariations[entry.key] == val;
                        return ChoiceChip(
                          label: Text(val),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedVariations[entry.key] = val;
                              });
                            }
                          },
                          selectedColor: AppColors.royalBlue,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.royalBlue
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.inkDark,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  // ── Specifications Card ───────────────────────────────────────────
  Widget _buildSpecificationsCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Specifications',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.inkDark,
            ),
          ),
          const SizedBox(height: 12),
          ...product.specifications.entries.map((spec) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      spec.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      spec.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Highlights Card ───────────────────────────────────────────────
  Widget _buildHighlightsCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Highlights',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.inkDark,
            ),
          ),
          const SizedBox(height: 12),
          ...product.highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
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

  // ── Brand Tile ────────────────────────────────────────────────────
  Widget _buildBrandTile(ProductModel product) {
    return FutureBuilder<DocumentSnapshot?>(
      future: product.brandId != null
          ? FirebaseFirestore.instance
              .collection('brands')
              .doc(product.brandId)
              .get()
          : Future.value(null),
      builder: (context, snapshot) {
        String? logoUrl;
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          logoUrl = data['logoUrl'] as String?;
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              if (logoUrl != null && logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    logoUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      product.brand.isNotEmpty
                          ? product.brand[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.royalBlue,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand.isNotEmpty ? product.brand : 'Maruti',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Official Brand Store',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Policy Tile ───────────────────────────────────────────────────
  Widget _buildPolicyTile(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.published_with_changes_rounded,
              color: AppColors.royalBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.returnPolicy ?? '72 Hours Easy Replacement',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '100% Genuine stationery directly from trusted sources',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Customer Reviews Section (100% Real Live Firestore Reviews) ─────
  Widget _buildReviewsAction(ProductModel product) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      color: AppColors.royalBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkDark,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/catalog/product/${product.id}/rate'),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(
                  'Write Review',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.star_outline_rounded,
                        size: 36,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No customer reviews yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Be the first to share your experience with this item!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/catalog/product/${product.id}/rate'),
                        icon: const Icon(Icons.star_rate_rounded, size: 18),
                        label: const Text('Rate & Review This Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Compute stats
              double avg = 0;
              for (final r in reviews) {
                avg += r.rating;
              }
              avg /= reviews.length;

              // Display summary & preview of top 2 reviews
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < avg.floor()
                                    ? Icons.star_rounded
                                    : (i < avg
                                        ? Icons.star_half_rounded
                                        : Icons.star_border_rounded),
                                color: const Color(0xFFF59E0B),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Based on ${reviews.length} verified customer ${reviews.length == 1 ? 'review' : 'reviews'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Show up to 2 real reviews
                  ...reviews.take(2).map((r) {
                    final initial = r.userName.isNotEmpty
                        ? r.userName[0].toUpperCase()
                        : 'U';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.royalBlue.withValues(alpha: 0.12),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.inkDark,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < r.rating
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.text.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              r.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(r.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context
                          .push('/catalog/product/${product.id}/reviews'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.royalBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(
                        'View All ${reviews.length} Reviews',
                        style: const TextStyle(
                          color: AppColors.royalBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Could not load reviews: $e',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggested Products ────────────────────────────────────────────
  Widget _buildSuggestedProducts(ProductModel currentProduct) {
    final relatedAsync = ref.watch(
      getRelatedProductsProvider(currentProduct.categoryId, currentProduct.id),
    );
    return relatedAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggested Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: 165,
                    child: ProductCard(product: products[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  // ── Top Products ──────────────────────────────────────────────────
  Widget _buildTopProducts(ProductModel currentProduct) {
    final topAsync = ref.watch(getNewArrivalsProvider(limit: 10));
    return topAsync.when(
      data: (products) {
        final filtered =
            products.where((p) => p.id != currentProduct.id).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: 165,
                    child: ProductCard(product: filtered[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  // ── Bottom Fixed Purchase Bar ─────────────────────────────────────
  Widget _buildBottomPurchaseBar(ProductModel product, bool isInCart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quantity Selector Capsule: [ –  1  + ]
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _qty > 1
                        ? () => setState(() => _qty--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    iconSize: 18,
                    color: _qty > 1
                        ? AppColors.inkDark
                        : AppColors.textHint,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$_qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _qty < product.stock
                        ? () => setState(() => _qty++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    iconSize: 18,
                    color: _qty < product.stock
                        ? AppColors.inkDark
                        : AppColors.textHint,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Buy Now (Secondary: Royal Blue outline / button)
            if (product.isInStock) ...[
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _buyNow(product),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.royalBlue,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor:
                          AppColors.royalBlue.withValues(alpha: 0.04),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Add to Cart (Primary: Vibrant Orange with Shopping Cart Icon)
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: product.isInStock
                      ? () {
                          if (isInCart) {
                            context.push('/cart');
                          } else {
                            _addToBag(product);
                          }
                        }
                      : null,
                  icon: Icon(
                    isInCart
                        ? Icons.shopping_bag_outlined
                        : Icons.shopping_cart_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    product.isInStock
                        ? (isInCart ? 'Go to Cart' : 'Add to Cart')
                        : 'Out of Stock',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: product.isInStock
                        ? AppColors.primary
                        : AppColors.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
