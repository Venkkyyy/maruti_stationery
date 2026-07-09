import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../models/cart_item_model.dart';
import '../../../core/utils/formatters.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            Text('${cartNotifier.totalItems} items in your cart', style: TextStyle(fontSize: 13, color: context.colors.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: context.colors.textHint),
                  const SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/catalog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start Shopping'),
                  )
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // _buildDeliveryBanner(),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _buildCartItem(items[i], cartNotifier),
                      ),
                      const SizedBox(height: 8),
                      _buildCouponsSection(cartNotifier.subtotal),
                      const SizedBox(height: 8),
                      _buildPriceDetails(cartNotifier),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading cart: $err')),
      ),
      bottomSheet: cartAsync.value?.isNotEmpty == true ? _buildBottomBar(context, cartNotifier) : null,
    );
  }

  Widget _buildDeliveryBanner() {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Deliver to: ',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                children: [
                  TextSpan(text: 'Current Address', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, CartNotifier cartNotifier) {
    return Container(
      color: context.colors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: item.image.isNotEmpty 
                      ? Image.network(item.image, fit: BoxFit.contain)
                      : Icon(Icons.edit_rounded, color: context.colors.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => cartNotifier.updateQty(item.productId, item.qty - 1),
                                  child: Icon(Icons.remove, size: 16, color: context.colors.textSecondary),
                                ),
                                const SizedBox(width: 8),
                                Text('${item.qty}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => cartNotifier.updateQty(item.productId, item.qty + 1),
                                  child: Icon(Icons.add, size: 16, color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(AppFormatters.formatPrice(item.price), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.colors.textSecondary, size: 20),
                  onPressed: () => cartNotifier.removeItem(item.productId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.divider),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => cartNotifier.removeItem(item.productId),
                  icon: Icon(Icons.delete_outline, size: 18, color: context.colors.textSecondary),
                  label: Text('REMOVE', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              Container(width: 1, height: 24, color: context.colors.divider),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    await ref.read(wishlistProvider.notifier).addByProductId(item.productId);
                    cartNotifier.removeItem(item.productId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Moved to Wishlist')),
                      );
                    }
                  },
                  icon: Icon(Icons.favorite_border, size: 18, color: context.colors.textSecondary),
                  label: Text('MOVE TO WISHLIST', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsSection(int subtotal) {
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final activeCouponsAsync = ref.watch(activeCouponsProvider);

    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined, size: 18, color: context.colors.textSecondary),
              const SizedBox(width: 8),
              Text('COUPONS & OFFERS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (appliedCoupon != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.success),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: context.colors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${appliedCoupon.code} applied', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.success)),
                        Text('You saved ${AppFormatters.formatPrice(appliedCoupon.discountAmount)}', style: TextStyle(fontSize: 12, color: context.colors.success)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(appliedCouponProvider.notifier).removeCoupon();
                      _couponController.clear();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE8EAF6)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter coupon code',
                            hintStyle: TextStyle(color: context.colors.primary.withValues(alpha: 0.5), fontSize: 13),
                          ),
                        ),
                      ),
                      _isApplyingCoupon
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : TextButton(
                              onPressed: () async {
                                final code = _couponController.text.trim();
                                if (code.isEmpty) return;
                                
                                setState(() => _isApplyingCoupon = true);
                                try {
                                  await ref.read(appliedCouponProvider.notifier).applyCoupon(code, subtotal);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isApplyingCoupon = false);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFE8EAF6),
                                foregroundColor: Colors.black87,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(3),
                                    bottomRight: Radius.circular(3),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                activeCouponsAsync.when(
                  data: (coupons) {
                    if (coupons.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, color: Color(0xFF2E7D32), size: 14),
                            const SizedBox(width: 4),
                            const Text('Available offers for you', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...coupons.map((coupon) {
                          final canApply = subtotal >= coupon.minOrderAmount;
                          final difference = coupon.minOrderAmount - subtotal;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: canApply ? context.colors.primary.withValues(alpha: 0.05) : context.colors.surfaceGrey.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: canApply ? context.colors.primary.withValues(alpha: 0.3) : context.colors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        coupon.code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: canApply ? context.colors.primary : context.colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Save ${AppFormatters.formatPrice(coupon.discountAmount)} on orders above ${AppFormatters.formatPrice(coupon.minOrderAmount)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      if (!canApply) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add ${AppFormatters.formatPrice(difference)} more to apply',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: context.colors.error,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (canApply)
                                  TextButton(
                                    onPressed: () async {
                                      _couponController.text = coupon.code;
                                      setState(() => _isApplyingCoupon = true);
                                      try {
                                        await ref.read(appliedCouponProvider.notifier).applyCoupon(coupon.code, subtotal);
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error),
                                          );
                                        }
                                      } finally {
                                        if (mounted) setState(() => _isApplyingCoupon = false);
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: context.colors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails(CartNotifier cartNotifier) {
    final subtotal = cartNotifier.subtotal;
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final discount = appliedCoupon?.discountAmount ?? 0;
    final total = (subtotal - discount) > 0 ? (subtotal - discount) : 0;

    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRICE DETAILS (${cartNotifier.totalItems} ITEMS)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.colors.textSecondary)),
          const SizedBox(height: 16),
          _priceRow('Total MRP', AppFormatters.formatPrice(subtotal)),
          if (discount > 0) ...[
            const SizedBox(height: 12),
            _priceRow('Coupon Discount', '-${AppFormatters.formatPrice(discount)}', isGreen: true),
          ],
          const SizedBox(height: 12),
          _priceRow('Shipping Fee', 'Free', isGreen: true),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
              Text(AppFormatters.formatPrice(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isGreen = false, bool isAction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            color: isGreen ? context.colors.success : (isAction ? context.colors.primary : context.colors.textPrimary), 
            fontWeight: isAction ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          )
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CartNotifier cartNotifier) {
    final subtotal = cartNotifier.subtotal;
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final discount = appliedCoupon?.discountAmount ?? 0;
    final total = (subtotal - discount) > 0 ? (subtotal - discount) : 0;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppFormatters.formatPrice(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                Text('VIEW DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.colors.primary)),
              ],
            ),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout/address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('PLACE ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
