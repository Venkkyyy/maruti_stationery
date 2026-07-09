import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/providers/theme_provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/router/admin_router.dart';
import 'providers/app_mode_provider.dart';

import 'firebase_options.dart';
import 'services/local_notification_service.dart';

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
  } catch (e) {
    debugPrint("Local notifications initialization failed: $e");
  }

  debugPrint("runApp START");
  runApp(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.admin),
      ],
      child: const MarutiAdminApp(),
    ),
  );
  debugPrint("runApp END");
}

class MarutiAdminApp extends ConsumerWidget {
  const MarutiAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Maruti Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}
