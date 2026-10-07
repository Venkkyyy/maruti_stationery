import 'package:cloud_firestore/cloud_firestore.dart';

enum ReturnStatus { pending, accepted, rejected, completed }
enum RefundMethod { points, money }

class ReturnRequestModel {
  final String id;
  final String orderId;
  final String userId;
  final List<ReturnItem> items;
  final String reason;
  final ReturnStatus status;
  final RefundMethod? refundMethod;
  final int totalRefundAmount; // in paise
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReturnRequestModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.reason,
    required this.status,
    this.refundMethod,
    required this.totalRefundAmount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReturnRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReturnRequestModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => ReturnItem.fromMap(e as Map<String, dynamic>))
              .toList() ?? [],
      reason: data['reason'] ?? '',
      status: ReturnStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReturnStatus.pending,
      ),
      refundMethod: data['refundMethod'] != null
          ? RefundMethod.values.firstWhere(
              (e) => e.name == data['refundMethod'],
              orElse: () => RefundMethod.money,
            )
          : null,
      totalRefundAmount: (data['totalRefundAmount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'reason': reason,
        'status': status.name,
        'refundMethod': refundMethod?.name,
        'totalRefundAmount': totalRefundAmount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class ReturnItem {
  final String productId;
  final String name;
  final String image;
  final int qty;
  final int price;

  const ReturnItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.qty,
    required this.price,
  });

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'image': image,
        'qty': qty,
        'price': price,
      };
}
