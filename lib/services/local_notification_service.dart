import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert' as dart_convert;
import 'package:go_router/go_router.dart' as go_router;
import '../core/router/app_router.dart' as maruti_router;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          handleNotificationTap(details.payload!);
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'maruti_stationery_channel',
        'Orders & Updates',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: notificationDetails,
    );
  }
  static void handleNotificationTap(String payload) {
    try {
      final data = dart_convert.jsonDecode(payload);
      final type = data['type'];
      
      final context = maruti_router.rootNavigatorKey.currentContext;
      if (context == null) return;
      
      if (type == 'offer' || type == 'coupon') {
        go_router.GoRouter.of(context).go('/catalog');
      } else if (type == 'order' || type == 'order_update') {
        final orderId = data['orderId'] ?? data['id'];
        if (orderId != null) {
          go_router.GoRouter.of(context).go('/orders/$orderId');
        }
      }
    } catch (e) {
      // Failed to parse payload or navigate
    }
  }
}
