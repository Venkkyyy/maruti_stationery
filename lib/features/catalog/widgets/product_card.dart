import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductCard  –  Exact Reference Card (Pure White, 20px Radius, Orange Arrow)
// ─────────────────────────────────────────────────────────────────────────────

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
  });

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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.push('/catalog/product/${p.id}');
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : const Color(0x28000000), // clearly visible drop shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0.8,
            ),
            if (!isDark)
              const BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGE (Soft warm background container matching reference) ──
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF242424) : AppColors.surfaceWarm,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildImage(p, context),
                      ),

                      // Top-Left Discount Badge
                      if (p.isOnSale)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.5, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppFormatters.formatDiscount(p.mrp, p.price),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                      // Top-Right Wishlist Heart
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (isWishlisted) {
                                ref.read(wishlistProvider.notifier).remove(p.id);
                              } else {
                                ref.read(wishlistProvider.notifier).add(p);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 15,
                                color: isWishlisted
                                    ? AppColors.primary
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── DETAILS & REFERENCE ARROW BUTTON ──
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (p.brandId != null && p.brandId!.isNotEmpty)
                                ? p.brandId!
                                : 'Daily writing essentials',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      // Price and Orange Arrow Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppFormatters.formatPrice(p.price),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              if (p.isOnSale) ...[
                                const SizedBox(width: 4),
                                Text(
                                  AppFormatters.formatPrice(p.mrp),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: context.colors.textHint,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Reference Orange Round Arrow Button (or Stepper)
                          if (p.isInStock)
                            _buildActionButton(context, ref, qtyInCart, p)
                          else
                            Text(
                              'Sold Out',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textHint,
                              ),
                            ),
                        ],
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
      return Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 34,
          color: context.colors.border,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: p.images.first,
      fit: BoxFit.contain,
      memCacheWidth: 400,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 30,
          color: context.colors.border,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, WidgetRef ref, int qtyInCart, ProductModel p) {
    if (qtyInCart == 0) {
      // Exact Reference: Orange Circle with White Right Arrow
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(cartProvider.notifier).addItem(p, 1);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added to cart',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                duration: const Duration(milliseconds: 900),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary, // #EE6A2B
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Stepper when added
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                ref.read(cartProvider.notifier).updateQty(p.id, qtyInCart - 1),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.remove_rounded, size: 13, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$qtyInCart',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (qtyInCart >= p.stock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Max stock reached',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                return;
              }
              ref.read(cartProvider.notifier).updateQty(p.id, qtyInCart + 1);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(Icons.add_rounded, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact list-style card for catalog list view
// ─────────────────────────────────────────────────────────────────────────────
class ProductListCard extends StatelessWidget {
  final ProductModel product;
  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/catalog/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Container(
                width: 95,
                height: 95,
                color: isDark ? const Color(0xFF242424) : AppColors.surfaceWarm,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            Container(color: context.colors.surfaceGrey),
                        errorWidget: (_, __, ___) => Container(
                          color: context.colors.surfaceGrey,
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: context.colors.border,
                          ),
                        ),
                      )
                    : Container(
                        color: context.colors.surfaceGrey,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: context.colors.primary.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppFormatters.formatPrice(product.price),
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (product.isOnSale) ...[
                            const SizedBox(width: 6),
                            Text(
                              AppFormatters.formatPrice(product.mrp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
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
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
