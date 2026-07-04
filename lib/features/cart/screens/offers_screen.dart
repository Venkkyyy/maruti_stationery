import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_Coupon> coupons = [
      _Coupon(
        code: 'MARUTI50',
        title: 'FLAT ₹500 OFF',
        description: 'Get Flat ₹500 off on your first order. Minimum cart value ₹2000.',
        expiry: '31 Dec 2026',
      ),
      _Coupon(
        code: 'FREESHIP',
        title: 'FREE SHIPPING',
        description: 'Get free shipping on all orders over ₹999.',
        expiry: 'Unlimited',
      ),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Available Offers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tap on an offer to apply it to your shopping bag.',
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          ...coupons.map((c) => _CouponCard(coupon: c)),
        ],
      ),
    );
  }
}

class _Coupon {
  final String code;
  final String title;
  final String description;
  final String expiry;

  _Coupon({required this.code, required this.title, required this.description, required this.expiry});
}

class _CouponCard extends StatelessWidget {
  final _Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.border, style: BorderStyle.solid)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    coupon.code,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coupon ${coupon.code} applied!'),
                        backgroundColor: context.colors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    context.pop(coupon.code);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Valid till: ${coupon.expiry}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






