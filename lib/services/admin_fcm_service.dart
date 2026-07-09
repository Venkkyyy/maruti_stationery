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
    "private_key_id": "ba6d68daad567682aff1873177318f3b24ad5133",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC6bd454u+VN8cA\nohiFQtz1oHQ7dI83CGLXwMuwyinraOR4uN/wBYqBhJ9S20E/J3264iP0Gh7UXDTy\n8TIcGOm6/4PWr8tTLWTtkP7FQMbB2zHmedWHLE2BJbEgzB475hCCUSoLVJKqW209\nMhNWAVN99vZ4j91bN4DoxegevwE3CVvyJTnxcM2Ldu7ZEfSjrM2r8c6YXPobrKTE\nlXgQNMAZ2PmzeKy2dogDAgd9CAZkn4cLMNmFQ01aMbkIg92wuHG/yBSVaXbzICWb\n+NL96sGtv/GMPjX2pvtcUPMNy04ZnaCn3jYfDzKwGYaHZ2UczN9YgrQYDr+X9S44\nBPs4sw09AgMBAAECggEAA2YM2tPNB9SeO1/5H/bN1emArPPNR5TOzn2ciQLKfFjr\nb1r5dCP5uC49hFJscFUNOPq16pWOUdNDgNlOT05R9n+BfQiz5XaKpD0UM+7gILkZ\nAglfD+mKGSxhfAZUl8V0MBgAMvgt+06S4X539UWtarq1mBGRWMAciMHQ3zyerkzk\nqV4T+9lldkxmEEQCmFVgiH+FXVWaHmY5Q32xLehOh3aC+J8IRxO6k3wcPAlh8BKG\nSPZYZXwUYm+GGIVC1jAAmzv2nKSg6gJPkZoNcgnnJTdqomN0kh/+Y4IrMx5q872d\n2r2rmYzIqBl7QAbna8tEOY3w0DejwLtq4YEbjyrjOQKBgQDfOcxueWJGuti7D9pz\nIHNHmH6zyEvfK731WOMyqpMmdfA7Pm7tBkYJ1wfQ2hLBHFWoTgkyp/u8fslUXMUf\nngh5ZeiIzbryHUTuf3LZd2m8gqlNfmL61+QCGEZg3ds8TDN5OSdVxDorLU9Q3E0+\npmKs9SpOAesayaAfWJkHxRz9FQKBgQDVzQa1F9/2kab2oUsIzfUld3LrfWtFCokj\nuUWZbGI+P+O5BLS0eBpIc4D/Dizu1XKO+rrVITVhf/zE3nNnQDNqc//TpSHx7Fww\nipQ2rh980B4C9ttLEO1leNjDFiWD0GZUkScwOwmyGG2tSIEsC3QaUisOJeXwr3DV\n5LozI1ppiQKBgGziBXyRisVTWGoONpDXcEOo94x8E74c2QB2xgOtvi8RcgeD0Zmd\n6MXd9DsEVAeL6aA5yDTESX9NHKkgwypD7IBCnCU2rIxyiHAJDJ1UqOfBmBFrp54R\ndm8rJhETxl9oD+d+YFhuaa0r4bdgbfE0OYeB4ovAVcxwMsF3dtWaaSRtAoGBAMgA\nWsTvh6BF0pWmfuXGnQwmeIeYtM9KMs4LU/NY83JeG+4JW+3y6EtcWZC/NwNZAyiD\nnmEgBqqlqtSTcAtngHGV//yB3oZMYFU8XbflHSmKGnkVakEHnbwt10BwKDntqrxz\naOByafiDZ54RVFzafgrdUM+UXkzQIdLFe/W4naxZAoGAVomHZ9sK8LJuTeRSjyhB\nJl70AkY/FzbPPWixgUkYnEgxJ3EIzurvQTMlDu1XTHrQ3I66rXhIfKt9+F6vEK32\nsD2iEoyZXLJhRpaAhEeQOz4DPdSQqsM7z4wKaUKbIL9Dt7+XVMAVSXgeaATn7DKx\ngw2RP5XwYFEnz0uSa1AO4QM=\n-----END PRIVATE KEY-----\n",
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
