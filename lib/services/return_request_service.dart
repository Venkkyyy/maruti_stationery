import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/return_request_model.dart';
import '../services/fcm_service.dart';
import '../services/admin_fcm_service.dart';

class ReturnRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new return request (Customer side)
  Future<void> createReturnRequest(ReturnRequestModel request) async {
    await _db.collection('return_requests').add(request.toFirestore());

    // Send notification to admin
    try {
      await AdminFCMService.sendNotification(
        targetTokenOrTopic: '/topics/admin',
        title: 'New Return Request',
        body: 'A customer has requested a return for order #${request.orderId}',
      );
    } catch (e) {
      // Ignore notification error
    }
  }

  // Get user's return requests
  Stream<List<ReturnRequestModel>> getUserReturnRequests(String userId) {
    return _db
        .collection('return_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ReturnRequestModel.fromFirestore(doc)).toList());
  }

  // Get all return requests (Admin side)
  Stream<List<ReturnRequestModel>> getAllReturnRequests() {
    return _db
        .collection('return_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ReturnRequestModel.fromFirestore(doc)).toList());
  }

  // Update return request status (Admin side)
  Future<void> updateReturnRequestStatus(
    String requestId, 
    ReturnStatus status, 
    RefundMethod? refundMethod,
    {String? userId}
  ) async {
    await _db.collection('return_requests').doc(requestId).update({
      'status': status.name,
      'refundMethod': refundMethod?.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null) {
      // Write to notifications collection
      await _db.collection('notifications').add({
        'title': 'Return Request ${status.name.toUpperCase()}',
        'body': 'Your return request has been ${status.name}.',
        'type': 'return',
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Send push notification
      try {
        final userDoc = await _db.collection('users').doc(userId).get();
        final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
        for (final token in tokens) {
          await AdminFCMService.sendNotification(
            targetTokenOrTopic: token,
            title: 'Return Request ${status.name.toUpperCase()}',
            body: 'Your return request has been ${status.name}.',
          );
        }
      } catch (e) {
        // Ignore
      }
    }
  }
}
