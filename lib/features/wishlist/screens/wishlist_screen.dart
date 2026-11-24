import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/cart_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  void _removeFromWishlist(
    BuildContext context,
    WidgetRef ref,
    String productId,
    String productName,
  ) {
    ref.read(wishlistProvider.notifier).remove(productId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "$productName" from wishlist'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCart(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    try {
      await ref.read(cartProvider.notifier).addItem(product, 1);
      if (context.mounted) {
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
                    'Added "${product.name}" to cart!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmClearWishlist(
    BuildContext context,
    WidgetRef ref,
    List<ProductModel> items,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.inkDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove all saved items from your wishlist?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final item in items) {
        ref.read(wishlistProvider.notifier).remove(item.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(watchWishlistProvider);
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.inkDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            const Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
                letterSpacing: -0.3,
              ),
            ),
            if (wishlistAsync.value?.isNotEmpty == true) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${wishlistAsync.value!.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (wishlistAsync.value?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: InkWell(
                  onTap: () => _confirmClearWishlist(
                    context,
                    ref,
                    wishlistAsync.value!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: wishlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyWishlist(context);
          }

          final cartProductIds =
              cartAsync.value?.map((i) => i.productId).toSet() ?? {};

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final product = items[i];
              final isInCart = cartProductIds.contains(product.id);

              return _buildWishlistCard(
                context: context,
                ref: ref,
                product: product,
                isInCart: isInCart,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load wishlist: $err',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  // ── Wishlist Card (Matching Screen 6 in Mockup) ───────────────────
  Widget _buildWishlistCard({
    required BuildContext context,
    required WidgetRef ref,
    required ProductModel product,
    required bool isInCart,
  }) {
    // Generate clean subtitle (e.g. "A4 - 300 Pages" or "Pack of 10" or Brand)
    String subtitle = '';
    if (product.specifications.isNotEmpty) {
      if (product.specifications.containsKey('Pages')) {
        subtitle = '${product.specifications['Pages']} Pages';
      } else if (product.specifications.containsKey('Pack Size')) {
        subtitle = 'Pack of ${product.specifications['Pack Size']}';
      } else {
        subtitle = product.specifications.values.first;
      }
    } else if (product.unit != 'piece') {
      subtitle = product.unit;
    } else if (product.brand.isNotEmpty) {
      subtitle = product.brand;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Product Image & Orange Discount Badge
          Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/catalog/product/${product.id}'),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: product.primaryImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.primaryImage,
                            fit: BoxFit.contain,
                            memCacheWidth: 200,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceWarm,
                            ),
                            errorWidget: (context, url, err) => const Icon(
                              Icons.auto_stories_rounded,
                              size: 30,
                              color: AppColors.textHint,
                            ),
                          )
                        : const Icon(
                            Icons.auto_stories_rounded,
                            size: 30,
                            color: AppColors.textHint,
                          ),
                  ),
                ),
              ),
              if (product.isOnSale && product.discountPercent > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCD8C6)),
                  ),
                  child: Text(
                    '${product.discountPercent}% OFF',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(width: 14),

          // Middle & Right: Details + Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Wishlist Heart Toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/catalog/product/${product.id}'),
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkDark,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Heart icon (tap removes from wishlist)
                    InkWell(
                      onTap: () => _removeFromWishlist(
                        context,
                        ref,
                        product.id,
                        product.name,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),

                // Subtitle / Specifications
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // Star Rating (if available)
                if (product.reviewCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${product.reviewCount})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Price Row & Orange "Add to Cart" Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkDark,
                          ),
                        ),
                        if (product.isOnSale)
                          Text(
                            'MRP ${AppFormatters.formatPrice(product.mrp)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    // Orange "Add to Cart" Button
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: product.isInStock
                            ? () => _addToCart(context, ref, product)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.isInStock
                              ? (isInCart
                                  ? AppColors.royalBlue
                                  : AppColors.primary)
                              : AppColors.surfaceGrey,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          product.isInStock
                              ? (isInCart ? 'In Cart ✓' : 'Add to Cart')
                              : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty Wishlist State ──────────────────────────────────────────
  Widget _buildEmptyWishlist(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Save your favourite stationery products and find them here whenever you need them.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Shop Now',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
