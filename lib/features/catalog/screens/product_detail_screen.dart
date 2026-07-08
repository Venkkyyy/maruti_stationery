import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../core/utils/formatters.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  static const String shopPhone = '+919876543210';

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _selectedImage = 0;
  bool _isAddingToBag = false;
  late AnimationController _stampController;
  late Animation<double> _stampScale;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stampScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  void _addToBag(product) async {
    setState(() => _isAddingToBag = true);
    _stampController.forward().then((_) => _stampController.reverse());
    try {
      await ref.read(cartProvider.notifier).addItem(product, 1);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() => _isAddingToBag = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Added to Shopping Bag!'),
              ],
            ),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToBag = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error),
        );
      }
    }
  }

  void _buyNow(product) async {
    try {
      await ref.read(cartProvider.notifier).addItem(product, 1);
      if (mounted) context.push('/cart');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(watchProductProvider(widget.productId));

    return productAsync.when(
      loading: () => Scaffold(backgroundColor: context.colors.background, body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: context.colors.background, body: Center(child: Text('Error: $e'))),
      data: (product) {
        if (product == null) return Scaffold(backgroundColor: context.colors.background, body: const Center(child: Text('Product not found.')));
        final bool isInStock = product.isInStock;
        
        final wishlistAsync = ref.watch(watchWishlistProvider);
        final isWishlisted = wishlistAsync.value?.any((p) => p.id == product.id) ?? false;
        
        return Scaffold(
          backgroundColor: context.colors.background,
          body: CustomScrollView(
        slivers: [
          // Collapsing image header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.colors.surface,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: context.colors.textPrimary),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: context.colors.textPrimary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sharing link copied!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: context.colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: context.colors.error,
                  ),
                  onPressed: () async {
                    if (isWishlisted) {
                      await ref.read(wishlistProvider.notifier).remove(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Removed from Wishlist'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } else {
                      await ref.read(wishlistProvider.notifier).add(product);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Added to Wishlist!'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.colors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image area
                  Container(
                    color: const Color(0xFFF1F3F4),
                    width: double.infinity,
                    height: double.infinity,
                    child: product.images.isNotEmpty
                      ? Image.network(product.images[_selectedImage], fit: BoxFit.contain)
                      : const Center(
                          child: Icon(Icons.image_not_supported_rounded,
                              size: 100, color: Color(0xFFBEC3C8)),
                        ),
                  ),
                  // Image pagination dots
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(product.images.length, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedImage = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _selectedImage == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _selectedImage == i
                                  ? context.colors.primary
                                  : context.colors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isInStock
                              ? context.colors.success.withValues(alpha: 0.1)
                              : context.colors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInStock
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 12,
                              color: isInStock
                                  ? context.colors.success
                                  : context.colors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isInStock ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isInStock
                                    ? context.colors.success
                                    : context.colors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Discount badge
                      if (product.isOnSale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppFormatters.formatDiscount(product.mrp, product.price),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating Summary (Clickable to Reviews Screen)
                  ref.watch(productReviewsProvider(widget.productId)).when(
                    data: (reviews) {
                      if (reviews.isEmpty) {
                        return GestureDetector(
                          onTap: () => context.push('/catalog/product/${widget.productId}/reviews'),
                          child: Row(
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(Icons.star_border_rounded, color: Colors.amber, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'No reviews yet',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.primary),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      double avgRating = 0;
                      for (var r in reviews) avgRating += r.rating;
                      avgRating /= reviews.length;
                      
                      return GestureDetector(
                        onTap: () => context.push('/catalog/product/${widget.productId}/reviews'),
                        child: Row(
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < avgRating.floor() 
                                    ? Icons.star_rounded 
                                    : (i < avgRating ? Icons.star_half_rounded : Icons.star_border_rounded),
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${avgRating.toStringAsFixed(1)}  •  ${reviews.length} reviews',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.primary),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Rate Product Button
                  GestureDetector(
                    onTap: () => context.push('/catalog/product/${widget.productId}/rate'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: context.colors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Rate Product',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    children: [
                      Text(
                        AppFormatters.formatPrice(product.price),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.colors.primary,
                        ),
                      ),
                      if (product.isOnSale) ...[
                        SizedBox(width: 10),
                        Text(
                          AppFormatters.formatPrice(product.mrp),
                          style: TextStyle(
                            fontSize: 16,
                            color: context.colors.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Product Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specifications
                  Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  _SpecRow('Brand', product.brand.isNotEmpty ? product.brand : 'Generic'),
                  _SpecRow('Category', product.categoryId),
                  _SpecRow('Status', product.isInStock ? 'In Stock' : 'Out of Stock'),
                  _SpecRow('SKU', product.id.substring(0, 8).toUpperCase()),

                  const SizedBox(height: 120), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Add-to-Bag bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: isInStock
            ? ScaleTransition(
                scale: _stampScale,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          icon: _isAddingToBag
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.shopping_bag_outlined, size: 20),
                          label: Text(_isAddingToBag ? 'Adding...' : 'Add to Bag'),
                          onPressed: _isAddingToBag ? null : () => _addToBag(product),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flash_on_rounded, size: 20),
                          label: const Text('Buy Now'),
                          onPressed: () => _buyNow(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: context.colors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Currently Out of Stock. Contact us for availability.',
                            style: TextStyle(
                              color: context.colors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colors.primary),
                      ),
                      icon: Icon(Icons.phone_rounded,
                          size: 18, color: context.colors.primary),
                      label: Text('+91 98765 43210'),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: ProductDetailScreen.shopPhone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ),
                ],
              ),
              ),
        );
      },
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}






