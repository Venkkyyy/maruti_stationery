import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';
import 'package:uuid/uuid.dart';

class AdminCouponService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCoupon(CouponModel coupon) async {
    final id = const Uuid().v4();
    final newCoupon = CouponModel(
      id: id,
      code: coupon.code.toUpperCase(),
      name: coupon.name,
      description: coupon.description,
      discountType: coupon.discountType,
      discountAmount: coupon.discountAmount,
      maxDiscountAmount: coupon.maxDiscountAmount,
      minOrderAmount: coupon.minOrderAmount,
      isActive: true,
      startDate: coupon.startDate,
      expiryDate: coupon.expiryDate,
      usageLimit: coupon.usageLimit,
      usageLimitPerUser: coupon.usageLimitPerUser,
      customerEligibility: coupon.customerEligibility,
      createdAt: DateTime.now(),
    );

    // Create notification for users
    final notifRef = _db.collection('notifications').doc();
    
    await _db.runTransaction((tx) async {
      tx.set(_db.collection('coupons').doc(id), newCoupon.toFirestore());
      
      // Create notification only if it's currently active and start date is past/now
      if (newCoupon.startDate.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
        String msg = '';
        if (newCoupon.discountType == 'flat') {
          msg = 'Get ₹${(newCoupon.discountAmount / 100).toStringAsFixed(0)} off on your orders!';
        } else if (newCoupon.discountType == 'percentage') {
          msg = 'Get ${newCoupon.discountAmount}% off on your orders!';
        } else {
          msg = 'Use code to get special offers on your orders!';
        }

        tx.set(notifRef, {
          'title': 'New Special Offer! 🎁',
          'body': 'Use code ${newCoupon.code.toUpperCase()} to $msg',
          'type': 'coupon',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  Future<void> editCoupon(String id, CouponModel updatedCoupon) async {
    await _db.collection('coupons').doc(id).update(updatedCoupon.toFirestore());
  }

  Future<void> toggleCouponStatus(String couponId, bool currentStatus) async {
    await _db.collection('coupons').doc(couponId).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> deleteCoupon(String couponId) async {
    await _db.collection('coupons').doc(couponId).delete();
  }
}
