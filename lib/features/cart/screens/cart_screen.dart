import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/cart_item_model.dart';
import '../../../core/utils/formatters.dart';

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
                      _buildDeliveryBanner(),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _buildCartItem(items[i], cartNotifier),
                      ),
                      const SizedBox(height: 8),
                      _buildCouponsSection(),
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
                  onPressed: () {},
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

  Widget _buildCouponsSection() {
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
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Enter coupon code', style: TextStyle(color: context.colors.textHint, fontSize: 14)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails(CartNotifier cartNotifier) {
    final subtotal = cartNotifier.subtotal;
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRICE DETAILS (${cartNotifier.totalItems} ITEMS)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.colors.textSecondary)),
          const SizedBox(height: 16),
          _priceRow('Total MRP', AppFormatters.formatPrice(subtotal)),
          const SizedBox(height: 12),
          _priceRow('Shipping Fee', 'Free', isGreen: true),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
              Text(AppFormatters.formatPrice(subtotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
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
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -2))],
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
                Text(AppFormatters.formatPrice(cartNotifier.subtotal), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
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
