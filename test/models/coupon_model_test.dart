import 'package:flutter_test/flutter_test.dart';
import 'package:maruti_stationery/models/coupon_model.dart';

void main() {
  group('CouponModel - calculateDiscount', () {
    final now = DateTime.now();

    test('calculates percentage discount correctly when below max discount', () {
      final coupon = CouponModel(
        id: '1',
        code: 'PERC20',
        name: '20% OFF',
        description: '',
        discountType: 'percentage',
        discountAmount: 20, // 20%
        maxDiscountAmount: 5000, // ₹50 (5000 paise)
        minOrderAmount: 0,
        isActive: true,
        startDate: now,
        expiryDate: now.add(const Duration(days: 1)),
        customerEligibility: 'all',
        createdAt: now,
      );

      // Subtotal: ₹100 (10000 paise)
      // 20% of 10000 = 2000 paise (₹20)
      final subtotal = 10000;
      final discount = coupon.calculateDiscount(subtotal);

      expect(discount, 2000);
    });

    test('caps percentage discount at maxDiscountAmount', () {
      final coupon = CouponModel(
        id: '2',
        code: 'PERC20MAX',
        name: '20% OFF up to ₹50',
        description: '',
        discountType: 'percentage',
        discountAmount: 20, // 20%
        maxDiscountAmount: 5000, // ₹50 (5000 paise)
        minOrderAmount: 0,
        isActive: true,
        startDate: now,
        expiryDate: now.add(const Duration(days: 1)),
        customerEligibility: 'all',
        createdAt: now,
      );

      // Subtotal: ₹1000 (100000 paise)
      // 20% of 100000 = 20000 paise (₹200)
      // But max discount is 5000 paise (₹50)
      final subtotal = 100000;
      final discount = coupon.calculateDiscount(subtotal);

      expect(discount, 5000);
    });

    test('calculates percentage discount correctly without maxDiscountAmount', () {
      final coupon = CouponModel(
        id: '3',
        code: 'PERC20UNLIMITED',
        name: '20% OFF Unlimited',
        description: '',
        discountType: 'percentage',
        discountAmount: 20, // 20%
        maxDiscountAmount: 0, // 0 means no limit
        minOrderAmount: 0,
        isActive: true,
        startDate: now,
        expiryDate: now.add(const Duration(days: 1)),
        customerEligibility: 'all',
        createdAt: now,
      );

      // Subtotal: ₹2000 (200000 paise)
      // 20% of 200000 = 40000 paise (₹400)
      final subtotal = 200000;
      final discount = coupon.calculateDiscount(subtotal);

      expect(discount, 40000);
    });

    test('returns flat discount amount correctly', () {
      final coupon = CouponModel(
        id: '4',
        code: 'FLAT100',
        name: '₹100 OFF',
        description: '',
        discountType: 'flat',
        discountAmount: 10000, // ₹100 (10000 paise)
        maxDiscountAmount: 0,
        minOrderAmount: 0,
        isActive: true,
        startDate: now,
        expiryDate: now.add(const Duration(days: 1)),
        customerEligibility: 'all',
        createdAt: now,
      );

      // Subtotal doesn't matter for flat discount
      final subtotal1 = 50000; // ₹500
      final subtotal2 = 1000000; // ₹10000

      expect(coupon.calculateDiscount(subtotal1), 10000);
      expect(coupon.calculateDiscount(subtotal2), 10000);
    });
  });
}
