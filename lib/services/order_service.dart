import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../core/errors/app_exception.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream orders for current user — real-time updates
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _db.collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // Stream single order — for order detail / tracking screen
  Stream<OrderModel?> watchOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map(
      (doc) => doc.exists ? OrderModel.fromFirestore(doc) : null,
    );
  }

  // Cancel order — only allowed in 'placed' or 'confirmed' status
  Future<void> cancelOrder(String orderId, String userId) async {
    await _db.runTransaction((transaction) async {
      final orderRef = _db.collection('orders').doc(orderId);
      final orderDoc = await transaction.get(orderRef);
      
      if (!orderDoc.exists) throw const AppException('Order not found');
      
      final order = OrderModel.fromFirestore(orderDoc);
      
      // Security check — user can only cancel their own orders
      if (order.userId != userId) throw const AppException('Unauthorized');
      
      if (!order.isCancellable) {
        throw const AppException('This order cannot be cancelled');
      }
      
      // Restore stock for each item
      for (final item in order.items) {
        final productRef = _db.collection('products').doc(item.productId);
        transaction.update(productRef, {
          'stock': FieldValue.increment(item.qty),
        });
      }
      
      // Update order status
      transaction.update(orderRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
