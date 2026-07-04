import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/providers/theme_provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar over content
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase (wrapped in try-catch in case options/config are not yet deployed)
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Crashlytics even in debug (optional during dev)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Catch Flutter errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint("Firebase initialization bypassed or failed: $e");
  }

  runApp(
    const ProviderScope(
      child: MarutiApp(),
    ),
  );
}

class MarutiApp extends ConsumerWidget {
  const MarutiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

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
