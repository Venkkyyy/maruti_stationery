import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';
import 'admin_fcm_service.dart';

/// Top-level background message handler required by FirebaseMessaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message received: ${message.messageId}');
  final notification = message.notification;
  if (notification != null) {
    await LocalNotificationService.showNotification(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title ?? 'Maruti Stationery',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }
}

/// Firebase Cloud Messaging service handling token registration,
/// topic subscriptions, and push message reception.
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String userId, {bool isAdmin = false}) async {
    try {
      // 1. Request notification permissions (iOS & Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCMService: Permission status: ${settings.authorizationStatus}');

      // 2. Fetch current FCM token and persist to Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        await saveToken(userId, token);
      }

      // 3. Listen for token refresh and update Firestore
      _messaging.onTokenRefresh.listen((newToken) {
        saveToken(userId, newToken);
      });

      // 4. Topic subscriptions
      await _updateSubscriptions(isAdmin);

      // 5. Handle foreground messages with LocalNotification banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCMService: Foreground message received: ${message.notification?.title}');
        final notif = message.notification;
        if (notif != null) {
          LocalNotificationService.showNotification(
            id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: notif.title ?? 'Maruti Stationery',
            body: notif.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });

      // 6. Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCMService: Notification opened from background');
        if (message.data.isNotEmpty) {
          LocalNotificationService.handleNotificationTap(jsonEncode(message.data));
        }
      });

      // 7. Handle notification click when app is opened from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        debugPrint('FCMService: Notification opened from terminated state');
        LocalNotificationService.handleNotificationTap(jsonEncode(initialMessage.data));
      }

      debugPrint('FCMService: successfully initialized for user $userId (isAdmin: $isAdmin)');
    } catch (e) {
      debugPrint('FCMService: initialization error: $e');
    }
  }

  /// Subscribes or unsubscribes from global broadcast topics
  Future<void> _updateSubscriptions(bool isAdmin) async {
    try {
      if (isAdmin) {
        await _messaging.subscribeToTopic('admin');
        await _messaging.unsubscribeFromTopic('offers');
        await _messaging.unsubscribeFromTopic('coupons');
        await _messaging.unsubscribeFromTopic('all');
      } else {
        await _messaging.subscribeToTopic('offers');
        await _messaging.subscribeToTopic('coupons');
        await _messaging.subscribeToTopic('all');
        await _messaging.unsubscribeFromTopic('admin');
      }
      debugPrint('FCMService: topic subscriptions updated for isAdmin: $isAdmin');
    } catch (e) {
      debugPrint('FCMService: topic subscription error: $e');
    }
  }

  /// Saves a raw FCM device token to Firestore under the user's document.
  Future<void> saveToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCMService: token registered in Firestore for $userId');
    } catch (e) {
      debugPrint('FCMService: error saving token: $e');
    }
  }

  /// Broadcasts an order status update to a customer across in-app notifications
  /// and direct push notifications.
  static Future<void> sendOrderStatusNotification({
    required String orderId,
    required String userId,
    required String status,
    String? customTitle,
    String? customBody,
  }) async {
    try {
      final String title;
      final String body;

      final normalizedStatus = status.toLowerCase();
      if (customTitle != null && customBody != null) {
        title = customTitle;
        body = customBody;
      } else {
        switch (normalizedStatus) {
          case 'confirmed':
            title = 'Order Confirmed! ✅';
            body = 'Your order #${orderId.toUpperCase()} has been confirmed and is being processed.';
            break;
          case 'packed':
            title = 'Order Packed! 📦';
            body = 'Your stationery items for order #${orderId.toUpperCase()} are securely packed.';
            break;
          case 'shipped':
            title = 'Order Out for Delivery! 🚚';
            body = 'Your order #${orderId.toUpperCase()} has been shipped and will reach you soon!';
            break;
          case 'delivered':
            title = 'Order Delivered! 🎉';
            body = 'Your order #${orderId.toUpperCase()} has been delivered successfully. Thank you for shopping with Maruti Stationery!';
            break;
          case 'cancelled':
            title = 'Order Cancelled';
            body = 'Order #${orderId.toUpperCase()} has been cancelled.';
            break;
          default:
            title = 'Order Update';
            body = 'Status for order #${orderId.toUpperCase()}: ${status.toUpperCase()}';
        }
      }

      // 1. Record in-app notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'order',
        'orderId': orderId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 2. Fetch customer's device tokens and dispatch push notifications
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
      for (final token in tokens) {
        await AdminFCMService.sendNotification(
          targetTokenOrTopic: token,
          title: title,
          body: body,
          data: {
            'type': 'order',
            'orderId': orderId,
            'status': normalizedStatus,
          },
        );
      }
    } catch (e) {
      debugPrint('FCMService: sendOrderStatusNotification error: $e');
    }
  }

  /// Shows a local notification directly.
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
