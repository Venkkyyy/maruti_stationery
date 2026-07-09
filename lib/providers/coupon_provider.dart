import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/coupon_model.dart';

part 'coupon_provider.g.dart';

@riverpod
Stream<List<CouponModel>> watchActiveCoupons(Ref ref) {
  return FirebaseFirestore.instance
      .collection('coupons')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => CouponModel.fromFirestore(doc)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
}
