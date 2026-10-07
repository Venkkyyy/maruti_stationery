import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/router/delivery_router.dart';
import 'providers/app_mode_provider.dart';

import 'firebase_options.dart';
import 'services/local_notification_service.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY APP ENTRY POINT
// Run with: flutter run --release --flavor delivery -t lib/main_delivery.dart
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      FlutterError.dumpErrorToConsole(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return const SizedBox.shrink();
    };
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  try {
    await LocalNotificationService.initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Notifications init failed: $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.delivery),
      ],
      child: const MarutiDeliveryApp(),
    ),
  );
}

class MarutiDeliveryApp extends ConsumerWidget {
  const MarutiDeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (prev, next) {
      final user = next.value;
      if (user != null) {
        FCMService().initialize(user.uid, isAdmin: false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        FCMService().initialize(user.uid, isAdmin: false);
      }
    });

    return MaterialApp.router(
      title: 'Maruti Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        primaryColor: const Color(0xFF00BFA5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BFA5)),
      ),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(deliveryRouterProvider),
    );
  }
}
