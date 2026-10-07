import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class AdminFCMService {
  static const String _projectId = 'maruti-stationery-d7862';
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  
  static const Map<String, dynamic> _serviceAccount = {
    "type": "service_account",
    "project_id": "maruti-stationery-d7862",
    "private_key_id": "REMOVED_FOR_SECURITY",
    "private_key": "REMOVED_FOR_SECURITY",
    "client_email": "firebase-adminsdk-fbsvc@maruti-stationery-d7862.iam.gserviceaccount.com",
    "client_id": "REMOVED_FOR_SECURITY",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40maruti-stationery-d7862.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  static Future<String?> _getAccessToken() async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(_serviceAccount);
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  static Future<void> sendNotification({
    required String targetTokenOrTopic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return;

      final bool isTopic = targetTokenOrTopic.startsWith('/topics/');
      final targetKey = isTopic ? 'topic' : 'token';
      final targetValue = isTopic ? targetTokenOrTopic.replaceFirst('/topics/', '') : targetTokenOrTopic;

      final Map<String, dynamic> msgBody = {
        targetKey: targetValue,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': 'maruti_stationery_channel_v2',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
          }
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
          },
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'content-available': 1,
              'sound': 'default',
            }
          }
        },
      };

      if (data != null && data.isNotEmpty) {
        msgBody['data'] = data;
      }

      final Map<String, dynamic> message = {
        'message': msgBody
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM V1 Notification sent successfully');
      } else {
        debugPrint('Failed to send FCM V1 Notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending FCM V1 notification: $e');
    }
  }
}
