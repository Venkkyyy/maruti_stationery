import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/formatters.dart';
import 'fcm_service.dart';
import 'loyalty_service.dart';

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

  // Create new order and update stock — uses a transaction to prevent overselling.
  // Returns the number of loyalty points credited.
  Future<int> createOrder(OrderModel order) async {
    // Fetch the loyalty rule before the transaction
    int pointsPer100 = 10; // default
    try {
      final ruleDoc = await _db.collection('settings').doc('loyalty_rule').get();
      if (ruleDoc.exists && ruleDoc.data() != null) {
        pointsPer100 = (ruleDoc.data()!['pointsPer100'] as num?)?.toInt() ?? 10;
      }
    } catch (_) {}

    // Calculate points: total is in paise; divide by 10000 to get ₹100 units
    final pointsEarned = (order.total ~/ 10000) * pointsPer100;

    await _db.runTransaction((transaction) async {
      // First, read all product documents to validate stock
      final productRefs = order.items
          .map((item) => _db.collection('products').doc(item.productId))
          .toList();

      final productDocs = await Future.wait(
        productRefs.map((ref) => transaction.get(ref)),
      );

      // Validate stock for each item before making any writes
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        final doc = productDocs[i];
        if (!doc.exists) {
          throw AppException('Product "${item.name}" is no longer available.');
        }
        final currentStock = doc.data()?['stock'] as int? ?? 0;
        if (currentStock < item.qty) {
          throw AppException(
            'Only $currentStock unit(s) of "${item.name}" left in stock. Please update your cart.',
          );
        }
      }

      // All stock checks passed — write order (with pointsEarned) and decrement stock
      final orderRef = _db.collection('orders').doc(order.id);
      // Write order with pointsEarned baked in
      final orderData = order.toFirestore();
      orderData['pointsEarned'] = pointsEarned;
      transaction.set(orderRef, orderData);

      for (int i = 0; i < order.items.length; i++) {
        transaction.update(productRefs[i], {
          'stock': FieldValue.increment(-order.items[i].qty),
          'salesCount': FieldValue.increment(order.items[i].qty),
        });
      }

      // Write admin notification for new order
      final adminNotifRef = _db.collection('admin_notifications').doc();
      transaction.set(adminNotifRef, {
        'type': 'new_order',
        'orderId': order.id,
        'userId': order.userId,
        'total': order.total,
        'itemCount': order.items.length,
        'pointsEarned': pointsEarned,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    });

    // Credit loyalty points (outside main transaction — failure here is non-fatal)
    if (pointsEarned > 0) {
      try {
        await LoyaltyService().creditPoints(
          userId: order.userId,
          orderId: order.id,
          pointsEarned: pointsEarned,
        );
      } catch (_) {
        // Non-fatal — points can be manually credited by admin if needed
      }
    }

    // Send push notification to admin topic
    try {
      await FCMService().sendNotification(
        targetTokenOrTopic: '/topics/admin',
        title: 'New Order Received!',
        body: 'Order #${order.id.substring(0, 8).toUpperCase()} for ${AppFormatters.formatPrice(order.total)}',
        data: {
          'type': 'order',
          'orderId': order.id,
        },
      );
    } catch (_) {}

    return pointsEarned;
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
