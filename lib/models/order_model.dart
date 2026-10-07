import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

enum OrderStatus { placed, confirmed, packed, shipped, delivered, cancelled, returned }
enum PaymentMethod { upi, card, netbanking, cod }
enum PaymentStatus { pending, paid, failed, refunded }

class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status;
  final List<OrderItem> items;
  final AddressModel address;
  final int subtotal;
  final int deliveryCharge;
  final int discount;
  final int total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String idempotencyKey;  // CRITICAL for duplicate prevention
  final int pointsEarned;       // loyalty points credited on this order
  final int pointsUsed;         // loyalty points redeemed on this order
  final String? deliveryCode;   // 6 digit code for driver verification
  final String? deliveryPartnerId; // ID of the assigned delivery partner
  final DateTime? deliveredAt;     // When the order was actually delivered
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.items,
    required this.address,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.idempotencyKey,
    this.pointsEarned = 0,
    this.pointsUsed = 0,
    this.deliveryCode,
    this.deliveryPartnerId,
    this.deliveredAt,
    required this.createdAt,
  });

  // Computed
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isCancellable => 
    status == OrderStatus.placed || status == OrderStatus.confirmed;
  
  String get statusLabel {
    return switch (status) {
      OrderStatus.placed => 'Order Placed',
      OrderStatus.confirmed => 'Confirmed',
      OrderStatus.packed => 'Packed',
      OrderStatus.shipped => 'Shipped',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
      OrderStatus.returned => 'Returned',
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.placed,
      ),
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ?? [],
      address: AddressModel.fromMap(data['address'] as Map<String, dynamic>? ?? {}),
      subtotal: (data['subtotal'] as num).toInt(),
      deliveryCharge: (data['deliveryCharge'] as num).toInt(),
      discount: (data['discount'] as num).toInt(),
      total: (data['total'] as num).toInt(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.cod,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      razorpayOrderId: data['razorpayOrderId'],
      razorpayPaymentId: data['razorpayPaymentId'],
      idempotencyKey: data['idempotencyKey'] ?? '',
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
      pointsUsed: (data['pointsUsed'] as num?)?.toInt() ?? 0,
      deliveryCode: data['deliveryCode'],
      deliveryPartnerId: data['deliveryPartnerId'],
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'status': status.name,
    'items': items.map((e) => e.toMap()).toList(),
    'address': address.toMap(),
    'subtotal': subtotal,
    'deliveryCharge': deliveryCharge,
    'discount': discount,
    'total': total,
    'paymentMethod': paymentMethod.name,
    'paymentStatus': paymentStatus.name,
    'razorpayOrderId': razorpayOrderId,
    'razorpayPaymentId': razorpayPaymentId,
    'idempotencyKey': idempotencyKey,
    'pointsEarned': pointsEarned,
    'pointsUsed': pointsUsed,
    'deliveryCode': deliveryCode,
    'deliveryPartnerId': deliveryPartnerId,
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class OrderItem {
  final String productId;
  final String name;
  final String image;
  final int price;    // snapshot at order time — product price may change later
  final int qty;
  final String unit;
  final Map<String, String> selectedVariations;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
    required this.unit,
    this.selectedVariations = const {},
  });

  int get total => price * qty;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num).toInt(),
      qty: (map['qty'] as num).toInt(),
      unit: map['unit'] ?? 'piece',
      selectedVariations: map['selectedVariations'] != null
          ? Map<String, String>.from(map['selectedVariations'])
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'qty': qty,
      'unit': unit,
      'selectedVariations': selectedVariations,
    };
  }
}
