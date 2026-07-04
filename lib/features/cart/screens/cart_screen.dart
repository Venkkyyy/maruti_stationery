import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:maruti_stationery/core/constants/app_text_styles.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceGrey, // Slight grey to make white cards pop
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            Text('2 items in your cart', style: TextStyle(fontSize: 13, color: context.colors.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDeliveryBanner(),
                  const SizedBox(height: 8),
                  _buildCartItem('Parker Vector Rollerball Pen', 'Color: Black', 'Qty: 2', 450, 500, '10% OFF'),
                  const SizedBox(height: 8),
                  _buildCartItem('Moleskine A5 Dotted Journal', 'Size: A5', 'Qty: 1', 1250, 1250, ''),
                  const SizedBox(height: 8),
                  _buildCouponsSection(),
                  const SizedBox(height: 8),
                  _buildPriceDetails(),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context),
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
                  TextSpan(text: '400001, Mumbai', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                ],
              ),
            ),
          ),
          Text(
            'CHANGE',
            style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(String title, String attr1, String attr2, double price, double mrp, String off) {
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
                  child: Icon(Icons.edit_rounded, color: context.colors.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(attr1, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Text(attr2, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                                Icon(Icons.arrow_drop_down, size: 16, color: context.colors.textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                          if (mrp > price) ...[
                            const SizedBox(width: 6),
                            Text('?', style: TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: context.colors.textSecondary)),
                            const SizedBox(width: 6),
                            Text(off, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.success)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.colors.textSecondary, size: 20),
                  onPressed: () {},
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
                  onPressed: () {},
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: context.colors.success),
              const SizedBox(width: 6),
              Text('Available offers for you', style: TextStyle(color: context.colors.success.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRICE DETAILS (2 ITEMS)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.colors.textSecondary)),
          const SizedBox(height: 16),
          _priceRow('Total MRP', '?1,750.00'),
          const SizedBox(height: 12),
          _priceRow('Discount on MRP', '-?50.00', isGreen: true),
          const SizedBox(height: 12),
          _priceRow('Coupon Discount', 'Apply Coupon', isAction: true),
          const SizedBox(height: 12),
          _priceRow('Shipping Fee', 'Free', isGreen: true),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
              Text('?1,700.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.security_rounded, size: 24, color: context.colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Safe and Secure Payments. Easy returns. 100% Authentic products.', 
                  style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                ),
              ),
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

  Widget _buildBottomBar(BuildContext context) {
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
                Text('?1,700.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
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

