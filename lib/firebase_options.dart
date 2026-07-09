// File generated manually from GoogleService-Info.plist
// Run `flutterfire configure` to regenerate this file automatically.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // Reuse iOS config for macOS
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNtuUN-WABc5xW6NYapb7l2EDy68NS39o',
    appId: '1:731940586001:ios:515bacb2b21e5b1bada7b0',
    messagingSenderId: '731940586001',
    projectId: 'maruti-stationery-d7862',
    storageBucket: 'maruti-stationery-d7862.firebasestorage.app',
    iosClientId: '731940586001-mlf81vbuisoe3sgrnp2kpcgb63fbqik0.apps.googleusercontent.com',
    iosBundleId: 'com.maruti.stationery.marutiStationery',
  );

  // Android options — update appId and apiKey from your google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNtuUN-WABc5xW6NYapb7l2EDy68NS39o',
    appId: '1:731940586001:android:d74841431c0d651eada7b0',
    messagingSenderId: '731940586001',
    projectId: 'maruti-stationery-d7862',
    storageBucket: 'maruti-stationery-d7862.firebasestorage.app',
  );
}
