import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String discountType; // 'flat', 'percentage', 'free_delivery', 'first_order'
  final int discountAmount; // in paise
  final int maxDiscountAmount; // in paise, 0 means no limit
  final int minOrderAmount; // in paise
  final bool isActive;
  final DateTime startDate;
  final DateTime expiryDate;
  final int? usageLimit; // null means infinite
  final int? usageLimitPerUser;
  final String customerEligibility; // 'all', 'new', 'existing', 'recent_buyers', 'past_buyers'
  final DateTime createdAt;

  const CouponModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountAmount,
    this.maxDiscountAmount = 0,
    required this.minOrderAmount,
    required this.isActive,
    required this.startDate,
    required this.expiryDate,
    this.usageLimit,
    this.usageLimitPerUser,
    required this.customerEligibility,
    required this.createdAt,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] ?? 'flat',
      discountAmount: (data['discountAmount'] as num?)?.toInt() ?? 0,
      maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toInt() ?? 0,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? false,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usageLimit: (data['usageLimit'] as num?)?.toInt(),
      usageLimitPerUser: (data['usageLimitPerUser'] as num?)?.toInt(),
      customerEligibility: data['customerEligibility'] ?? 'all',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'minOrderAmount': minOrderAmount,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      if (usageLimit != null) 'usageLimit': usageLimit,
      if (usageLimitPerUser != null) 'usageLimitPerUser': usageLimitPerUser,
      'customerEligibility': customerEligibility,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int calculateDiscount(int subtotal) {
    if (discountType == 'percentage') {
      int calculated = (subtotal * discountAmount) ~/ 100;
      if (maxDiscountAmount > 0 && calculated > maxDiscountAmount) {
        return maxDiscountAmount;
      }
      return calculated;
    } else {
      return discountAmount;
    }
  }
}
