import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/providers/theme_provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/router/app_router.dart';

import 'firebase_options.dart';
import 'services/local_notification_service.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_mode_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    debugPrint("Firebase init START");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase init END - success");

    // Enable Crashlytics even in debug (optional during dev)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Catch Flutter errors
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      FlutterError.dumpErrorToConsole(errorDetails);
    };

    // Catch async errors
    
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      debugPrint('Async Error: $error\n$stack');
      return true;
    };
  } catch (e) {
    debugPrint("Firebase initialization bypassed or failed: $e");
  }

  try {
    await LocalNotificationService.initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Local notifications initialization failed: $e");
  }

  debugPrint("runApp START");
  runApp(
    const ProviderScope(
      child: MarutiApp(),
    ),
  );
  debugPrint("runApp END");
}

class MarutiApp extends ConsumerWidget {
  const MarutiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen(authStateProvider, (prev, next) {
      final user = next.value;
      if (user != null) {
        final appMode = ref.read(appModeProvider);
        FCMService().initialize(user.uid, isAdmin: appMode == AppMode.admin);
      }
    });

    return MaterialApp.router(
      title: 'Maruti Stationery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
