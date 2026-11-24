import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class AdminFCMService {
  static const String _projectId = 'maruti-stationery-d7862';
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  
  // Environment-provided Service Account JSON to prevent hardcoding secrets in source code
  static const String _envServiceAccountJson = String.fromEnvironment('FCM_SERVICE_ACCOUNT_JSON');

  static Future<String?> _getAccessToken() async {
    try {
      if (_envServiceAccountJson.isEmpty) {
        debugPrint('ℹ️ [AdminFCM] FCM_SERVICE_ACCOUNT_JSON not set. Automated notifications can also be sent via backend API.');
        return null;
      }
      final Map<String, dynamic> saMap = jsonDecode(_envServiceAccountJson);
      final accountCredentials = ServiceAccountCredentials.fromJson(saMap);
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
      if (token == null) {
        // Log in development without failing
        debugPrint('[AdminFCM Simulation] Target: $targetTokenOrTopic, Title: $title, Body: $body');
        return;
      }

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
            'default_vibrate_timings': true,
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
          },
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      if (data != null && data.isNotEmpty) {
        msgBody['data'] = data;
      }

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': msgBody}),
      );

      if (res.statusCode == 200) {
        debugPrint('FCM sent successfully to $targetTokenOrTopic');
      } else {
        debugPrint('FCM send failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Error sending FCM: $e');
    }
  }

  static Future<void> broadcastToAll({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    await sendNotification(
      targetTokenOrTopic: '/topics/all_users',
      title: title,
      body: body,
      data: data,
    );
  }
}
