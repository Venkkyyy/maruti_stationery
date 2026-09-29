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
    "private_key_id": "e86200872d46e03e91daaf13f35d6db921fe5e28",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC20ba5Fzp3HPxw\ndSJ0AXA/kiQE2jRtOmSqIbKMQHFa8wcT3PjCkHHf4bBu5VvXHhuyM63KWEdS4mXL\nZ67EBd6Q+MwNc4YHNvC/sj+e1IvL/HxsYc15JsKma35oQHPOr3Xa+Z2xtav2kK39\n+3xviCanI0nzChQ94jV/A9fheydMbEz2IOv9gPmnER5a8RPMDzFnarzeqyB98jYW\nzIugfn6JbxoT6j9J5HxTq1jIzLI6h6dayylHEdKwphiF+20QUaxa6Ko1DSvlAZjI\nF6JiMSnOjLpVrQhdXom6T1WDwGIQ/v2LG8GKXncViSFwEEbPTUm2NSmQh9PU0JJK\n/+V2o/RRAgMBAAECggEAKAgS0UO/Vx6/PibABRPdjuYCwhc/vJ05NrHLRX/E8ovd\nxGEyDXSQotvqBNZvPlMG8IX1a6XZ9FHDxX7uG1lHq4n3MIjX09OZcvhmivJyrBec\n7SSbWAh/Pe6yzsQyN5NfJLRc7fFgdsymdMNxM4DmKdoF0tSlqwlR+n6Ocn7Dk62S\nNHeQGiBLJG4/Js05tgb4158uVSfmnagbmwHiWDEJkt0ocO+BJByzeHHO8dRJTAj5\n1pKWMSEzgxk5VOHDM7lX79+Enn2voTBj0+4lJqJ2xR5W3CJ76G7Hp3U5t7QbKIo1\nkrgWCaJ++nA2c7Jh3RjzixD61GVcV3PCtq9a7M2gKwKBgQDrjoCmh6WfRuY3ebLN\neur614Y2emqbiJuSdocL+cyWIObptcYg1gWSxFxXNiSeDSn/mMi5nQvTv0dqUAqO\nqI0LSCrFpnIxlfb6FN4PNdBP+Jnkw7kOnZt7JL7Kt9ih7n/e0la4nIOScshIcb/J\nm3S4BavXdZkuz2rsI31Nm32uxwKBgQDGr4NKXN260Zl3lvs1VqsWhXlm6JQLzZbE\nG+fRuj1jFKX+HQLyHtEV57toTAAsyhhlsuRohAct/PYHV4V1Qw3tW7ah5q40x1SG\n6jSa8jrPjM5qhu5mbSVN5BXndoWFoPpnbSEJE6oXnLYcRnMj9DDBEebcpVemdeEz\nHq/94ksMJwKBgBZmPqWXUJCM1WeBExenEKE5zXFwwqJ3oxOSYdUps+KyzkJ7HpQQ\nxgbm1UEVzPWamtvLU4sS/ATus4PQiLB4JrFj821IHqPIduvhABzCKUTxhvDSC87v\n/dD/9YShZuA/JbmylryHZZuPfqwk5O/u8HJvV5/tdtuUrb42wbuXhaQRAoGAH5JY\nPILRQRR5XIWDWZByE1wWVIH0tINwx6zfg3YitxHa5qxZgXvgIaj3ILWi+XsLsW1h\n2jHQqkAeIECKFn4XQnZmaQes+voJtn6U6WJAciafzlGupFwHp37s9CDjSr6vy6uN\nqlGTn7jpP0j6luYAsU1U8A7eBLeKl4Ly2FcTMdUCgYApXyD3YkklOHh4k9ZnovqI\ng1WzrhLwB+wm/dpKFi8C/gQJJia4t7/mUteTn4byDgz0c7NMrQzx4CVuGhSqtqPf\nxXV70m9UqCyzfRXhF4HWljpQ/IE+FJWJnaq/55KxPJwVI9U4SqLIJljGQifJSd1i\npu2vsNOhszYVxsgoCYVANw==\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@maruti-stationery-d7862.iam.gserviceaccount.com",
    "client_id": "104083225308182380407",
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

      final Map<String, dynamic> message = {
        'message': {
          targetKey: targetValue,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'maruti_stationery_channel_v2',
              'sound': 'default',
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'content-available': 1,
                'sound': 'default',
              }
            }
          },
          'data': data ?? {},
        }
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
