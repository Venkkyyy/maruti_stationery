import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  void _removeFromWishlist(BuildContext context, WidgetRef ref, String id) {
    ref.read(wishlistNotifierProvider.notifier).remove(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Removed from wishlist'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addToBag(BuildContext context, ProductModel product) {
    // TODO: Connect to CartProvider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to bag!'),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(watchWishlistProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            if (wishlistAsync.hasValue)
              Text(
                '${wishlistAsync.value!.length} saved items',
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
          ],
        ),
      ),
      body: wishlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget.wishlist(
              onButtonPressed: () => context.go('/catalog'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSizes.screenHorizontal),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _WishlistCard(
              product: items[i],
              onRemove: () => _removeFromWishlist(context, ref, items[i].id),
              onAddToBag: () => _addToBag(context, items[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;
  final VoidCallback onAddToBag;

  const _WishlistCard({
    required this.product,
    required this.onRemove,
    required this.onAddToBag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/catalog/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: context.colors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: AppSizes.productCardImageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.cardRadius - 1),
                      topRight: Radius.circular(AppSizes.cardRadius - 1),
                    ),
                  ),
                  child: Icon(Icons.edit_rounded, size: 48, color: context.colors.border),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 8)],
                      ),
                      child: Icon(Icons.favorite_rounded, size: 16, color: context.colors.error),
                    ),
                  ),
                ),
                if (!product.isInStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSizes.cardRadius - 1),
                          topRight: Radius.circular(AppSizes.cardRadius - 1),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF\nSTOCK',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textPrimary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        AppFormatters.formatPrice(product.price),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                      ),
                      if (product.isOnSale) ...[
                        const SizedBox(width: 5),
                        Text(
                          AppFormatters.formatPrice(product.mrp),
                          style: TextStyle(fontSize: 11, color: context.colors.textHint, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: product.isInStock
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
                        ),
                        onPressed: onAddToBag,
                        child: const Text('Move to Bag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      )
                    : Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceGrey,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text('Notify Me', style: TextStyle(fontSize: 11, color: context.colors.textHint)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






