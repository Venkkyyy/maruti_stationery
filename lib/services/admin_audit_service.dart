import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_log_model.dart';
import '../models/stock_log_model.dart';

class AdminAuditService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Records an administrative action in `/audit_logs`
  static Future<void> logAction({
    required String action,
    required String targetType,
    required String targetId,
    required String description,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final adminName = user?.displayName ?? user?.email ?? 'Store Admin';
      final adminEmail = user?.email ?? '';

      final log = AuditLogModel(
        id: const Uuid().v4(),
        adminName: adminName,
        adminEmail: adminEmail,
        action: action,
        targetType: targetType,
        targetId: targetId,
        description: description,
        timestamp: DateTime.now(),
      );

      await _db.collection('audit_logs').doc(log.id).set(log.toFirestore());
    } catch (e) {
      debugPrint('Failed to record audit log: $e');
    }
  }

  /// Records an inventory stock adjustment in `/stock_logs`
  static Future<void> logStockMovement({
    required String productId,
    required String productName,
    required int quantityChange,
    required int previousStock,
    required int newStock,
    required String reason,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final adminName = user?.displayName ?? user?.email ?? 'System';

      final log = StockLogModel(
        id: const Uuid().v4(),
        productId: productId,
        productName: productName,
        quantityChange: quantityChange,
        previousStock: previousStock,
        newStock: newStock,
        reason: reason,
        timestamp: DateTime.now(),
        adminName: adminName,
      );

      await _db.collection('stock_logs').doc(log.id).set(log.toFirestore());
    } catch (e) {
      debugPrint('Failed to record stock log: $e');
    }
  }
}

