import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart';
import '../../../models/coupon_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_colors.dart';
import '../../catalog/widgets/product_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(int subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    try {
      await ref
          .read(appliedCouponProvider.notifier)
          .applyCoupon(code, subtotal);
      if (mounted) {
        _couponController.clear();
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
                Text('Coupon "$code" applied successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  void _confirmClearCart(CartNotifier cartNotifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cart',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.inkDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your shopping cart?',
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
      cartNotifier.clearCart();
    }
  }

  void _confirmRemoveItem(
    CartItemModel item,
    CartNotifier cartNotifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Item',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.inkDark,
          ),
        ),
        content: Text(
          'Remove "${item.name}" from your cart?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
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
              'Remove',
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
      cartNotifier.removeItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final deliverySettings =
        ref.watch(watchDeliverySettingsProvider).value ??
        const DeliverySettingsModel();

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
              'My Cart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
                letterSpacing: -0.3,
              ),
            ),
            if (cartAsync.value?.isNotEmpty == true) ...[
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
                  '${cartAsync.value?.fold<int>(0, (total, item) => total + item.qty) ?? 0}',
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
          if (cartAsync.value?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: InkWell(
                  onTap: () => _confirmClearCart(cartNotifier),
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
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyCart();
          }

          final subtotal = items.fold<int>(0, (total, item) => total + (item.price * item.qty));
          final isFreeDeliveryCoupon =
              appliedCoupon?.discountType == 'free_delivery';
          final isFreeDelivery =
              isFreeDeliveryCoupon ||
              subtotal >= deliverySettings.freeThreshold;
          final deliveryCharge = isFreeDelivery ? 0 : deliverySettings.fee;
          final discount = isFreeDeliveryCoupon
              ? 0
              : (appliedCoupon?.calculateDiscount(subtotal) ?? 0);
          final total =
              (subtotal + deliveryCharge - discount)
                  .clamp(0, double.maxFinite)
                  .toInt();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _buildCartItemCard(items[i], cartNotifier),
                      ),

                      const SizedBox(height: 20),

                      // Dedicated Coupon Section
                      _buildCouponSection(appliedCoupon, subtotal),

                      const SizedBox(height: 20),

                      // Price Details Order Summary Card
                      _buildPriceDetailsCard(
                        subtotal: subtotal,
                        discount: discount,
                        deliveryCharge: deliveryCharge,
                        isFreeDelivery: isFreeDelivery,
                        total: total,
                        deliverySettings: deliverySettings,
                      ),

                      const SizedBox(height: 28),

                      // Suggested Products Section
                      _buildSuggestedProducts(items),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom CTA: Proceed to Checkout ->
              _buildCheckoutBar(total, items),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load cart items: $err',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  // ── Cart Item Card ────────────────────────────────────────────────
  Widget _buildCartItemCard(CartItemModel item, CartNotifier cartNotifier) {
    // Watch product for MRP, stock, and discount percentage
    final productAsync = ref.watch(watchProductProvider(item.productId));
    final product = productAsync.value;

    final discountPercent = (product != null && product.mrp > product.price)
        ? (((product.mrp - product.price) / product.mrp) * 100).round()
        : null;

    final wishlistAsync = ref.watch(watchWishlistProvider);
    final isWishlisted =
        wishlistAsync.value?.any((p) => p.id == item.productId) ?? false;

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
          // Left: Product Image on warm background + Discount Tag
          Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/catalog/product/${item.productId}'),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: item.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.contain,
                            memCacheWidth: 200,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceWarm,
                            ),
                            errorWidget: (context, url, err) => const Icon(
                              Icons.auto_stories_rounded,
                              size: 28,
                              color: AppColors.textHint,
                            ),
                          )
                        : const Icon(
                            Icons.auto_stories_rounded,
                            size: 28,
                            color: AppColors.textHint,
                          ),
                  ),
                ),
              ),
              if (discountPercent != null && discountPercent > 0) ...[
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
                    '$discountPercent% OFF',
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

          // Middle & Right: Details + Stepper
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Wishlist + Remove
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/catalog/product/${item.productId}'),
                        child: Text(
                          item.name,
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

                    // Wishlist Button
                    InkWell(
                      onTap: () {
                        if (isWishlisted) {
                          ref
                              .read(wishlistProvider.notifier)
                              .remove(item.productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from Wishlist'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } else {
                          ref
                              .read(wishlistProvider.notifier)
                              .addByProductId(item.productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to Wishlist!'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 19,
                          color: isWishlisted
                              ? AppColors.error
                              : AppColors.textHint,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Remove item action
                    InkWell(
                      onTap: () => _confirmRemoveItem(item, cartNotifier),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),

                // Selected Variations / Subtitle
                if (item.selectedVariations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.selectedVariations.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Price and Quantity Stepper Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Unit Price & MRP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.formatPrice(item.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkDark,
                          ),
                        ),
                        if (product != null && product.isOnSale)
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

                    // Quantity Stepper: [ –  qty  + ]
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (item.qty > 1) {
                                cartNotifier.updateQty(item.id, item.qty - 1);
                              } else {
                                _confirmRemoveItem(item, cartNotifier);
                              }
                            },
                            icon: Icon(
                              item.qty > 1
                                  ? Icons.remove_rounded
                                  : Icons.delete_outline_rounded,
                            ),
                            iconSize: 16,
                            color: item.qty > 1
                                ? AppColors.inkDark
                                : AppColors.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            splashRadius: 14,
                          ),
                          Container(
                            width: 24,
                            alignment: Alignment.center,
                            child: Text(
                              '${item.qty}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkDark,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: (item.qty < item.stock)
                                ? () => cartNotifier.updateQty(
                                      item.id,
                                      item.qty + 1,
                                    )
                                : null,
                            icon: const Icon(Icons.add_rounded),
                            iconSize: 16,
                            color: (item.qty < item.stock)
                                ? AppColors.inkDark
                                : AppColors.textHint,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            splashRadius: 14,
                          ),
                        ],
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

  // ── Coupon Section ────────────────────────────────────────────────
  Widget _buildCouponSection(CouponModel? appliedCoupon, int subtotal) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.royalBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Coupons & Offers',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/cart/offers'),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'View Offers',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (appliedCoupon != null)
            // Applied Coupon State
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1F2D9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1E9A4B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coupon "${appliedCoupon.code}" Applied',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E9A4B),
                          ),
                        ),
                        Text(
                          appliedCoupon.discountType == 'free_delivery'
                              ? 'Free delivery unlocked!'
                              : 'You saved ${AppFormatters.formatPrice(appliedCoupon.calculateDiscount(subtotal))} on this order',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref
                        .read(appliedCouponProvider.notifier)
                        .removeCoupon(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF1E9A4B),
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            )
          else
            // Coupon Entry Field & Apply Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkDark,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isApplyingCoupon
                        ? null
                        : () => _applyCoupon(subtotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: _isApplyingCoupon
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Price Details (Order Summary Card) ────────────────────────────
  Widget _buildPriceDetailsCard({
    required int subtotal,
    required int discount,
    required int deliveryCharge,
    required bool isFreeDelivery,
    required int total,
    required DeliverySettingsModel deliverySettings,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.inkDark,
            ),
          ),
          const SizedBox(height: 14),

          // Subtotal
          _summaryRow('Item Total', AppFormatters.formatPrice(subtotal)),

          // Discount (if any)
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _summaryRow(
              'Discount',
              '- ${AppFormatters.formatPrice(discount)}',
              valueColor: const Color(0xFF1E9A4B),
              isBold: true,
            ),
          ],

          const SizedBox(height: 10),

          // Delivery Charges
          _summaryRow(
            'Delivery Charges',
            isFreeDelivery ? 'FREE' : AppFormatters.formatPrice(deliveryCharge),
            valueColor: isFreeDelivery
                ? const Color(0xFF1E9A4B)
                : AppColors.inkDark,
            isBold: isFreeDelivery,
          ),

          // Free Delivery Indicator
          if (!isFreeDelivery && subtotal < deliverySettings.freeThreshold) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Add ${AppFormatters.formatPrice(deliverySettings.freeThreshold - subtotal)} more for FREE delivery',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.inkDark,
                ),
              ),
              Text(
                AppFormatters.formatPrice(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.inkDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.inkDark,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Fixed Bottom Bar: Proceed to Checkout ─────────────────────────
  Widget _buildCheckoutBar(int total, List<CartItemModel> items) {
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // Validate cart items
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your cart is empty')),
                );
                return;
              }

              // Check for out-of-stock items
              final outOfStock = items.where((i) => i.qty > i.stock).toList();
              if (outOfStock.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${outOfStock.first.name} only has ${outOfStock.first.stock} in stock. Please adjust quantity.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              context.push('/checkout/address');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Checkout  •  ${AppFormatters.formatPrice(total)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggested Products Carousel ───────────────────────────────────
  Widget _buildSuggestedProducts(List<CartItemModel> cartItems) {
    final productsAsync = ref.watch(getNewArrivalsProvider(limit: 10));
    return productsAsync.when(
      data: (products) {
        final inCartIds = cartItems.map((e) => e.productId).toSet();
        final suggested =
            products.where((p) => !inCartIds.contains(p.id)).toList();
        if (suggested.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You Might Also Like',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggested.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: 165,
                    child: ProductCard(product: suggested[i]),
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

  // ── Empty Cart State ──────────────────────────────────────────────
  Widget _buildEmptyCart() {
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
                Icons.shopping_bag_outlined,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Looks like you haven\'t added any stationery items yet. Explore our curated school and office essentials.',
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
