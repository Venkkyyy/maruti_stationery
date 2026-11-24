import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';

/// Client service that integrates Flutter with the Maruti Stationery
/// Node.js + Nodemailer Gmail Automation Service.
class GmailAutomationService {
  static const String _defaultLocalUrl = 'http://localhost:5001';
  static const String _defaultAndroidEmulatorUrl = 'http://10.0.2.2:5001';

  /// Resolves the Gmail automation service base URL.
  /// Checks Firestore `/settings/integrations` for custom deployment URL,
  /// otherwise uses local development URL.
  static Future<String> _getBaseUrl() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('integrations')
          .get();
      if (doc.exists && doc.data()?['emailServiceUrl'] != null) {
        final url = doc.data()!['emailServiceUrl'].toString().trim();
        if (url.isNotEmpty) return url;
      }
    } catch (_) {}

    if (kIsWeb) return _defaultLocalUrl;
    if (Platform.isAndroid) return _defaultAndroidEmulatorUrl;
    return _defaultLocalUrl;
  }

  /// Sends the Order Confirmation Email via Gmail SMTP service.
  /// Trigger: Order successfully created and saved.
  static Future<void> sendOrderConfirmedEmail({
    required OrderModel order,
    String? customerEmail,
    String? customerName,
  }) async {
    try {
      // 1. Resolve recipient email — STRICTLY for the customer, NEVER for the admin
      String? to = customerEmail;
      String name = customerName ?? order.address.name;

      if (to == null || to.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          to = userData?['email'] as String?;
          if (customerName == null || customerName.isEmpty) {
            name = (userData?['name'] as String?) ?? order.address.name;
          }
        }
      }

      // If the customer has not registered an email, skip sending.
      // Never fall back to the currently logged in admin or delivery driver's email.
      if (to == null || to.trim().isEmpty) {
        debugPrint('ℹ️ [GmailAutomation] Customer (${order.userId}) does not have an email on file. Skipping confirmation email.');
        return;
      }

      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/email/order-confirmed');

      final payload = {
        'to': to,
        'orderId': order.id,
        'customerName': name,
        'orderDate': '${order.createdAt.day} ${_getMonthName(order.createdAt.month)} ${order.createdAt.year}',
        'items': order.items.map((item) => {
          'name': item.name,
          'qty': item.qty,
          'price': item.price,
        }).toList(),
        'subtotal': order.subtotal,
        'deliveryCharge': order.deliveryCharge,
        'discount': order.discount,
        'total': order.total,
        'deliveryAddress': {
          'name': order.address.name,
          'phone': order.address.phone,
          'street': order.address.street,
          'city': order.address.city,
          'state': order.address.state,
          'pincode': order.address.pincode,
        },
        'deliveryCode': order.deliveryCode ?? '',
      };

      debugPrint('📧 [GmailAutomation] Dispatching Order Confirmed email for #${order.id} to $to...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final success = response.statusCode == 200;

      // Log delivery event to Firestore for audit visibility
      await _logToFirestore(
        orderId: order.id,
        eventType: 'order_confirmed',
        recipientEmail: to,
        status: success ? 'sent' : 'failed',
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (success) {
        debugPrint('✅ [GmailAutomation] Order Confirmed email dispatched successfully for #${order.id}');
      } else {
        debugPrint('⚠️ [GmailAutomation] Service returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [GmailAutomation] Error sending order confirmation email: $e');
      // Record failed attempt in Firestore
      await _logToFirestore(
        orderId: order.id,
        eventType: 'order_confirmed',
        recipientEmail: customerEmail ?? 'unknown',
        status: 'error',
        statusCode: 0,
        responseBody: e.toString(),
      );
    }
  }

  /// Sends the Order Delivered Email via Gmail SMTP service.
  /// Trigger: Order status successfully changes to delivered after PIN verification.
  /// STRICT: Does NOT send or include the delivery PIN.
  static Future<void> sendOrderDeliveredEmail({
    required String orderId,
    required String userId,
    DateTime? deliveredAt,
    Map<String, dynamic>? addressMap,
    int itemCount = 0,
    String? customerEmail,
    String? customerName,
  }) async {
    try {
      // 1. Resolve recipient email — STRICTLY for the customer, NEVER for the admin
      String? to = customerEmail;
      String name = customerName ?? 'Valued Customer';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (to == null || to.isEmpty) {
          to = userData?['email'] as String?;
        }
        if (name == 'Valued Customer' && userData?['name'] != null) {
          name = userData!['name'].toString();
        }
      }

      // If the customer has not registered an email, skip sending.
      // Never fall back to the admin or delivery partner who is marking the order delivered.
      if (to == null || to.trim().isEmpty) {
        debugPrint('ℹ️ [GmailAutomation] Customer ($userId) does not have an email on file. Skipping delivered email.');
        return;
      }

      final deliveryTime = deliveredAt ?? DateTime.now();
      final formattedTime = '${deliveryTime.day} ${_getMonthName(deliveryTime.month)} ${deliveryTime.year} at ${_formatTime(deliveryTime)}';

      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/email/order-delivered');

      final payload = {
        'to': to,
        'orderId': orderId,
        'customerName': name,
        'deliveredAt': formattedTime,
        'deliveryAddress': addressMap ?? {},
        'itemCount': itemCount,
      };

      debugPrint('📧 [GmailAutomation] Dispatching Order Delivered email for #$orderId to $to...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final success = response.statusCode == 200;

      // Log delivery event to Firestore
      await _logToFirestore(
        orderId: orderId,
        eventType: 'order_delivered',
        recipientEmail: to,
        status: success ? 'sent' : 'failed',
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (success) {
        debugPrint('✅ [GmailAutomation] Order Delivered email dispatched successfully for #$orderId');
      } else {
        debugPrint('⚠️ [GmailAutomation] Service returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [GmailAutomation] Error sending order delivered email: $e');
      await _logToFirestore(
        orderId: orderId,
        eventType: 'order_delivered',
        recipientEmail: customerEmail ?? 'unknown',
        status: 'error',
        statusCode: 0,
        responseBody: e.toString(),
      );
    }
  }

  /// Logs email event to Firestore `/email_logs`
  static Future<void> _logToFirestore({
    required String orderId,
    required String eventType,
    required String recipientEmail,
    required String status,
    required int statusCode,
    required String responseBody,
  }) async {
    try {
      final docId = '${orderId.toUpperCase()}_$eventType';
      await FirebaseFirestore.instance.collection('email_logs').doc(docId).set({
        'orderId': orderId.toUpperCase(),
        'eventType': eventType,
        'recipientEmail': recipientEmail,
        'status': status,
        'statusCode': statusCode,
        'response': responseBody,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

