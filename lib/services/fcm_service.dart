import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_notification_service.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _serverKey = 'YOUR_SERVER_KEY_HERE';

  Future<void> initialize(String userId, {bool isAdmin = false}) async {
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

    // Update topics
    await _updateSubscriptions(isAdmin);

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
    if (message.notification != null) {
      LocalNotificationService.showNotification(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    LocalNotificationService.handleNotificationTap(jsonEncode(message.data));
  }

  Future<void> _updateSubscriptions(bool isAdmin) async {
    try {
      if (isAdmin) {
        await _messaging.subscribeToTopic('admin');
        await _messaging.unsubscribeFromTopic('offers');
      } else {
        await _messaging.subscribeToTopic('offers');
        await _messaging.unsubscribeFromTopic('admin');
      }
    } catch (e) {
      debugPrint('Topic subscription error: $e');
    }
  }

  Future<void> sendNotification({
    required String targetTokenOrTopic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (_serverKey == 'YOUR_SERVER_KEY_HERE') {
      debugPrint('WARNING: Cannot send FCM because Server Key is not set in FCMService.');
      return;
    }

    try {
      final to = targetTokenOrTopic;

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': to,
          'notification': {
            'title': title,
            'body': body,
          },
          if (data != null) 'data': data,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM sent successfully to $to');
      } else {
        debugPrint('FCM failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM send error: $e');
    }
  }
}
