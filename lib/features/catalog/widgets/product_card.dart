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
import '../../../providers/review_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductCard  –  aesthetic grid card based on reference UI
// ─────────────────────────────────────────────────────────────────────────────

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

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
      onTap: () {
        context.push('/catalog/product/${p.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGE (Flexible to take remaining space) ──
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(p, context),

                    // Top-Left Badge (Discount or Popular)
                    if (p.isOnSale)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppFormatters.formatDiscount(p.mrp, p.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else if (!p.isInStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Top-Right Wishlist Heart
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isWishlisted) {
                            ref.read(wishlistProvider.notifier).remove(p.id);
                          } else {
                            ref.read(wishlistProvider.notifier).add(p);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isWishlisted
                                ? Colors.red
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── INFO SECTION ───────
              Expanded(
                child: Container(
                  color: context.colors.surface,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product Name
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      
                      const Spacer(),

                      // Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatPrice(p.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (p.isOnSale) ...[
                            Text(
                              AppFormatters.formatPrice(p.mrp),
                              style: TextStyle(
                                fontSize: 10,
                                color: context.colors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(((p.mrp - p.price) / p.mrp) * 100).toInt()}% OFF',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Cart Control
                      if (p.isInStock)
                        SizedBox(
                          width: double.infinity,
                          child: _buildCartControl(context, ref, qtyInCart, p),
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
      return Container(
        color: context.colors.surfaceGrey,
        child: Center(
          child: Icon(Icons.inventory_2_outlined,
              size: 40, color: context.colors.border),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: p.images.first,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      placeholder: (_, __) => Container(color: context.colors.surfaceGrey),
      errorWidget: (_, __, ___) => Container(
        color: context.colors.surfaceGrey,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 32, color: context.colors.border),
        ),
      ),
    );
  }

  Widget _buildCartControl(
      BuildContext context, WidgetRef ref, int qtyInCart, ProductModel p) {
    if (qtyInCart == 0) {
      return GestureDetector(
        onTap: () => ref.read(cartProvider.notifier).addItem(p, 1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'ADD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    // Stepper when item is in cart
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QtyBtn(
            icon: Icons.remove,
            onTap: () =>
                ref.read(cartProvider.notifier).updateQty(p.id, qtyInCart - 1),
          ),
          Text(
            '$qtyInCart',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          _QtyBtn(
            icon: Icons.add,
            onTap: () {
              if (qtyInCart >= p.stock) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Max stock reached')));
                return;
              }
              ref.read(cartProvider.notifier).updateQty(p.id, qtyInCart + 1);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact list-style card for catalog list view (Unchanged)
// ─────────────────────────────────────────────────────────────────────────────
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
                            placeholder: (context, url) =>
                                Container(color: context.colors.surfaceGrey),
                            errorWidget: (context, url, error) => Container(
                              color: context.colors.surfaceGrey,
                              child: Icon(Icons.image_not_supported_rounded,
                                  color: context.colors.border),
                            ),
                          )
                        : Container(
                            color: context.colors.surfaceGrey,
                            child: Icon(Icons.edit_rounded,
                                size: 36,
                                color: context.colors.primary
                                    .withValues(alpha: 0.5)),
                          ),
                  ),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 0,
                    left: 0,
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
                        AppFormatters.formatDiscount(
                            product.mrp, product.price),
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
                      'SKU: ${product.id.toUpperCase()}',
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
