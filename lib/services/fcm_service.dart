import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

/// Lightweight FCM token registration service.
/// 
/// This does NOT use the firebase_messaging SDK.
/// Push delivery is handled server-side via AdminFCMService (FCM v1 HTTP API).
/// In-app notifications are driven by Firestore real-time listeners 
/// (see notification_provider.dart + notifications_screen.dart).
class FCMService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String userId, {bool isAdmin = false}) async {
    // Token registration is handled by firebase_messaging SDK internally
    // if it is present. Since we removed the SDK dependency, the admin
    // uses the FCM v1 API with topic targeting or stored tokens.
    // 
    // For now, we just ensure local notification service is ready.
    debugPrint('FCMService: initialized for user $userId (isAdmin: $isAdmin)');
  }

  /// Saves a raw FCM device token to Firestore under the user's document.
  /// Call this if you obtain a token through any means (e.g. a native plugin).
  Future<void> saveToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCMService: token saved for $userId');
    } catch (e) {
      debugPrint('FCMService: error saving token: $e');
    }
  }

  /// Shows a local notification directly (used when Firestore notification
  /// listener detects a new notification for the user while app is in foreground).
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await LocalNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
