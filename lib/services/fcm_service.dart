import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    // Request permission (required on iOS, optional on Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get FCM token and save to Firestore
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(userId, token);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Handle background tap — navigate to correct screen
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    debugPrint("Received foreground message: ${message.notification?.title}");
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'order_update') {
      // In production, trigger GoRouter navigation (e.g. context.go('/orders/${data['orderId']}'))
      debugPrint("Notification tapped with order update: ${data['orderId']}");
    }
  }
}
