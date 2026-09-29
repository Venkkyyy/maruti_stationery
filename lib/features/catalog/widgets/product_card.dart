import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';

/// Reusable product card for both home grid and catalog grid.
class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final wishlistAsync = ref.watch(watchWishlistProvider);
    final isWishlisted = wishlistAsync.value?.any((p) => p.id == product.id) ?? false;

    final qtyInCart = cartState.value
            ?.where((i) => i.productId == product.id)
            .fold(0, (sum, i) => sum + i.qty) ?? 0;

    return GestureDetector(
      onTap: () => context.push('/catalog/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: context.colors.surfaceGrey,
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.images.first,
                              fit: BoxFit.cover,
                              memCacheWidth: 400, // Optimize memory usage
                              placeholder: (context, url) => Container(color: context.colors.surfaceGrey),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported_rounded,
                                size: 40,
                                color: context.colors.border,
                              ),
                            )
                          : Icon(
                              Icons.edit_rounded,
                              size: 48,
                              color: context.colors.border,
                            ),
                    ),
                  ),
                  // Discount badge — muted amber, professional
                  if (product.isOnSale)
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB45309),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          AppFormatters.formatDiscount(product.mrp, product.price),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  // Wishlist Heart
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () {
                        if (isWishlisted) {
                          ref.read(wishlistProvider.notifier).remove(product.id);
                        } else {
                          ref.read(wishlistProvider.notifier).add(product);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isWishlisted ? Colors.red : context.colors.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppFormatters.formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (product.isOnSale) ...[
                          const SizedBox(width: 4),
                          Text(
                            AppFormatters.formatPrice(product.mrp),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${((product.mrp - product.price) / product.mrp * 100).round()}% off',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    // Rating Pill
                    if (product.reviewCount > 0)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(product.averageRating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 2),
                                const Icon(Icons.star, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewCount})',
                            style: TextStyle(fontSize: 11, color: context.colors.textHint),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, int qtyInCart) {
    if (!product.isInStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.surfaceGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('SOLD OUT', style: TextStyle(fontSize: 9, color: context.colors.textHint, fontWeight: FontWeight.bold)),
      );
    }

    if (qtyInCart == 0) {
      return SizedBox(
        height: 32,
        width: 64,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: context.colors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: context.colors.surface,
            foregroundColor: context.colors.primary,
          ),
          onPressed: () {
            ref.read(cartProvider.notifier).addItem(product, 1);
          },
          child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      );
    }

    // Inline qty selector (solid pill)
    return Container(
      height: 32,
      width: 64,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              ref.read(cartProvider.notifier).updateQty(product.id, qtyInCart - 1);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.remove, size: 14, color: Colors.white),
            ),
          ),
          Text('$qtyInCart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          InkWell(
            onTap: () {
              if (qtyInCart >= product.stock) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max stock reached')));
                return;
              }
              ref.read(cartProvider.notifier).updateQty(product.id, qtyInCart + 1);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact list-style product card for catalog screen
class ProductListCard extends StatelessWidget {
  final ProductModel product;

  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/catalog/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: context.colors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  child: SizedBox(
                    width: AppSizes.productListThumbSize,
                    height: AppSizes.productListCardHeight,
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            placeholder: (context, url) => Container(color: context.colors.surfaceGrey),
                            errorWidget: (context, url, error) => Container(
                              color: context.colors.surfaceGrey,
                              child: Icon(Icons.image_not_supported_rounded,
                                  color: context.colors.border),
                            ),
                          )
                        : Container(
                            color: context.colors.surfaceGrey,
                            child: Icon(
                              Icons.edit_rounded,
                              size: 36,
                              color: context.colors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB45309),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomRight: Radius.circular(7),
                        ),
                      ),
                      child: Text(
                        AppFormatters.formatDiscount(product.mrp, product.price),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (!product.isInStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'OUT OF\nSTOCK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                          fontSize: 11, color: context.colors.textHint),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          AppFormatters.formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (product.isOnSale) ...[
                          const SizedBox(width: 6),
                          Text(
                            AppFormatters.formatPrice(product.mrp),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: context.colors.textHint, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
