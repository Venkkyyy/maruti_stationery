import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';
import 'package:uuid/uuid.dart';

class AdminCouponService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCoupon({
    required String code,
    required int discountAmount,
    required int minOrderAmount,
    required DateTime expiryDate,
  }) async {
    final id = const Uuid().v4();
    final coupon = CouponModel(
      id: id,
      code: code.toUpperCase(),
      discountAmount: discountAmount,
      minOrderAmount: minOrderAmount,
      isActive: true,
      expiryDate: expiryDate,
      createdAt: DateTime.now(),
    );

    // Create notification for users
    final notifRef = _db.collection('notifications').doc();
    
    await _db.runTransaction((tx) async {
      tx.set(_db.collection('coupons').doc(id), coupon.toFirestore());
      tx.set(notifRef, {
        'title': 'New Special Offer! 🎁',
        'body': 'Use code ${code.toUpperCase()} to get ₹${(discountAmount / 100).toStringAsFixed(2)} off on your orders!',
        'type': 'coupon',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    });
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
