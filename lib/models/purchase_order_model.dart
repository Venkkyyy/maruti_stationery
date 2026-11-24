import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final int unitCost; // In paise
  final int totalCost; // In paise

  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (map['unitCost'] as num?)?.toInt() ?? 0,
      totalCost: (map['totalCost'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': totalCost,
    };
  }
}

enum PurchaseStatus { pending, received, cancelled }

class PurchaseOrderModel {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String supplierName;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final List<PurchaseItem> items;
  final int totalCost; // In paise
  final PurchaseStatus status;
  final String notes;
  final bool isRestocked;
  final DateTime createdAt;

  const PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.items,
    required this.totalCost,
    this.status = PurchaseStatus.received,
    this.notes = '',
    this.isRestocked = true,
    required this.createdAt,
  });

  factory PurchaseOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsRaw = (data['items'] as List<dynamic>?) ?? [];
    return PurchaseOrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: itemsRaw.map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>)).toList(),
      totalCost: (data['totalCost'] as num?)?.toInt() ?? 0,
      status: PurchaseStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PurchaseStatus.received,
      ),
      notes: data['notes'] ?? '',
      isRestocked: data['isRestocked'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'items': items.map((e) => e.toMap()).toList(),
      'totalCost': totalCost,
      'status': status.name,
      'notes': notes,
      'isRestocked': isRestocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

