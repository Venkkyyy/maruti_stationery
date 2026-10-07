import 'dart:ui';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../models/cart_item_model.dart';
import '../../../core/utils/formatters.dart';
import '../../catalog/widgets/product_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final deliverySettings = ref.watch(watchDeliverySettingsProvider).value ?? const DeliverySettingsModel();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'My Cart',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.colors.textPrimary),
            onPressed: () async {
              if (cartAsync.value != null && cartAsync.value!.isNotEmpty) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: context.colors.surface,
                    title: Text('Clear Cart', style: TextStyle(color: context.colors.textPrimary)),
                    content: Text('Are you sure you want to remove all items from your cart?', style: TextStyle(color: context.colors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => context.pop(true),
                        child: Text('Clear', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  cartNotifier.clearCart();
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
              Color(0xFFFFF1F2),
              Color(0xFFF0FDF4),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: context.colors.textHint),
                  const SizedBox(height: 24),
                  Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    "Looks like you haven't added anything to your cart yet",
                    style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Explore Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, i) => _buildCartItem(items[i], cartNotifier),
                        ),
                        const SizedBox(height: 24),
                        _buildPriceDetails(cartNotifier, appliedCoupon, deliverySettings),
                        const SizedBox(height: 32),
                        _buildSuggestedProducts(items),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading cart: ')),
      ),
        ),
      ),
      bottomSheet: cartAsync.value?.isNotEmpty == true ? _buildBottomBar(context, cartNotifier) : null,
    );
  }

  Widget _buildCartItem(CartItemModel item, CartNotifier cartNotifier) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.surfaceGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.image.isNotEmpty 
                ? CachedNetworkImage(
                    imageUrl: item.image,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                  )
                : Icon(Icons.image, color: context.colors.border, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name, 
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.colors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ref.read(wishlistProvider.notifier).addByProductId(item.productId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Wishlist')));
                      },
                      child: Icon(Icons.favorite_border_rounded, size: 18, color: context.colors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: context.colors.surface,
                            title: Text('Remove Item', style: TextStyle(color: context.colors.textPrimary)),
                            content: Text('Are you sure you want to remove this item from your cart?', style: TextStyle(color: context.colors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(false),
                                child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => context.pop(true),
                                child: Text('Remove', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          cartNotifier.removeItem(item.id);
                        }
                      },
                      child: Icon(Icons.close_rounded, size: 18, color: context.colors.textSecondary),
                    ),
                  ],
                ),
                if (item.selectedVariations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.selectedVariations.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                    style: TextStyle(fontSize: 11, color: context.colors.textHint),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatPrice(item.price), 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.qty > 1) cartNotifier.updateQty(item.id, item.qty - 1);
                            },
                            child: Icon(Icons.remove, size: 16, color: context.colors.textPrimary),
                          ),
                          const SizedBox(width: 12),
                          Text('${item.qty}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => cartNotifier.updateQty(item.id, item.qty + 1),
                            child: Icon(Icons.add, size: 16, color: context.colors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.formatPrice(item.price * item.qty), 
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
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

  Widget _buildPriceDetails(CartNotifier cartNotifier, dynamic appliedCoupon, DeliverySettingsModel deliverySettings) {
    final subtotal = cartNotifier.subtotal;
    
    final isFreeDeliveryCoupon = appliedCoupon?.discountType == 'free_delivery';
    final isFreeDelivery = isFreeDeliveryCoupon || subtotal >= deliverySettings.freeThreshold;
    final deliveryCharge = isFreeDelivery ? 0 : deliverySettings.fee;
    
    final discount = isFreeDeliveryCoupon ? 0 : (appliedCoupon?.calculateDiscount(subtotal) ?? 0);
    final total = (subtotal + deliveryCharge - discount).clamp(0, double.maxFinite).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary)),
        const SizedBox(height: 16),
        _priceRow('Subtotal', AppFormatters.formatPrice(subtotal)),
        if (discount > 0) ...[
          const SizedBox(height: 12),
          _priceRow('Discount', '- ${AppFormatters.formatPrice(discount)}'),
        ],
        const SizedBox(height: 12),
        _priceRow(
          'Shipping', 
          isFreeDelivery ? 'FREE' : AppFormatters.formatPrice(deliveryCharge), 
          isGreen: isFreeDelivery,
        ),
        const SizedBox(height: 16),
        Divider(color: context.colors.border.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
            Text(AppFormatters.formatPrice(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.colors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            color: isGreen ? context.colors.success : context.colors.textPrimary,
            fontSize: 14,
            fontWeight: isGreen ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CartNotifier cartNotifier) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/checkout/address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedProducts(List<CartItemModel> cartItems) {
    final productsAsync = ref.watch(getNewArrivalsProvider(limit: 10));
    return productsAsync.when(
      data: (products) {
        final inCartIds = cartItems.map((e) => e.productId).toSet();
        final suggested = products.where((p) => !inCartIds.contains(p.id)).toList();
        if (suggested.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggested.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: 155,
                    child: ProductCard(product: suggested[i]),
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
  }
}
