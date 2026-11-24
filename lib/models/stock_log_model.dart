import 'package:cloud_firestore/cloud_firestore.dart';

class StockLogModel {
  final String id;
  final String productId;
  final String productName;
  final int quantityChange;
  final int previousStock;
  final int newStock;
  final String reason;
  final DateTime timestamp;
  final String adminName;

  const StockLogModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityChange,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    required this.timestamp,
    this.adminName = 'System',
  });

  factory StockLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockLogModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantityChange: (data['quantityChange'] as num?)?.toInt() ?? 0,
      previousStock: (data['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (data['newStock'] as num?)?.toInt() ?? 0,
      reason: data['reason'] ?? 'Manual Adjustment',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminName: data['adminName'] ?? 'System',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityChange': quantityChange,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'adminName': adminName,
    };
  }
}

