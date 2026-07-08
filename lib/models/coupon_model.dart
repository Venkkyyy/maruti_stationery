import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final int discountAmount; // in paise
  final int minOrderAmount; // in paise
  final bool isActive;
  final DateTime expiryDate;
  final DateTime createdAt;

  const CouponModel({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.minOrderAmount,
    required this.isActive,
    required this.expiryDate,
    required this.createdAt,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      discountAmount: (data['discountAmount'] as num?)?.toInt() ?? 0,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? false,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'discountAmount': discountAmount,
      'minOrderAmount': minOrderAmount,
      'isActive': isActive,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
