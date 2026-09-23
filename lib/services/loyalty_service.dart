import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles crediting loyalty points to a user after a completed order.
class LoyaltyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Credit loyalty points for an order.
  ///
  /// [userId]      — the customer's Firebase UID
  /// [orderId]     — the order ID for audit trail
  /// [pointsEarned] — pre-calculated points to credit
  ///
  /// Uses a Firestore transaction to atomically:
  ///   1. Increment the user's `loyaltyPoints` field
  ///   2. Write an audit record in `loyalty_transactions`
  Future<void> creditPoints({
    required String userId,
    required String orderId,
    required int pointsEarned,
  }) async {
    if (pointsEarned <= 0) return;

    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);

      // Atomically increment user's points balance
      transaction.update(userRef, {
        'loyaltyPoints': FieldValue.increment(pointsEarned),
      });

      // Write an auditable transaction log
      final txnRef = _db.collection('loyalty_transactions').doc();
      transaction.set(txnRef, {
        'userId': userId,
        'orderId': orderId,
        'pointsEarned': pointsEarned,
        'type': 'order_credit',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Manually adjust a user's points balance (admin use).
  ///
  /// [delta] can be positive (add) or negative (deduct).
  Future<void> adjustPoints({
    required String userId,
    required int delta,
    String reason = 'admin_adjustment',
  }) async {
    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);

      transaction.update(userRef, {
        'loyaltyPoints': FieldValue.increment(delta),
      });

      final txnRef = _db.collection('loyalty_transactions').doc();
      transaction.set(txnRef, {
        'userId': userId,
        'orderId': null,
        'pointsEarned': delta,
        'type': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get the current loyalty points balance for a user.
  Future<int> getBalance(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return 0;
    return (doc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
  }
}
