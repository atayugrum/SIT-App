// File: flutter_app/lib/firebase_options.dart
// Default Firebase options for your SIT App project.

// IMPORTANT: Generated based on the Firebase project 'sit-app-project'
// and the specific app configurations you provided.

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        // Using iOS options for macOS as a common practice.
        // If you have a separate macOS config, you can add it.
        return ios;
      case TargetPlatform.windows:
        // Windows configuration would typically be added here if registered.
        // For now, this will throw an error if run on Windows.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running "flutterfire configure".',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running "flutterfire configure".',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ------------- WEB -------------
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAPellV7Rqarfy4z1xs7Xw_waSkfqG2_ys',
    appId: '1:454101274107:web:e4f9d41ce1d6a163ae0f5e',
    messagingSenderId: '454101274107',
    projectId: 'sit-app-project',
    authDomain: 'sit-app-project.firebaseapp.com',
    storageBucket: 'sit-app-project.firebasestorage.app',
    // measurementId: 'YOUR_WEB_MEASUREMENT_ID_IF_ANY', // Optional
  );

  // ------------- ANDROID -------------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAfsB2QYzbgrf6POMb6HKor3HqQTsRWDgk',
    appId: '1:454101274107:android:4c441fc9cafadd27ae0f5e',
    messagingSenderId: '454101274107',
    projectId: 'sit-app-project',
    storageBucket: 'sit-app-project.firebasestorage.app',
  );

  // ------------- iOS and macOS -------------
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_38GMz3W8tXCXUyADh_ZajU1YOMmrQ44',
    appId: '1:454101274107:ios:93f3f3214bcc8d3dae0f5e',
    messagingSenderId: '454101274107',
    projectId: 'sit-app-project',
    storageBucket: 'sit-app-project.firebasestorage.app',
    iosBundleId: 'com.example.flutterApp',
    // If you had an iosClientId in your GoogleService-Info.plist, you could add it:
    // iosClientId: 'YOUR_IOS_CLIENT_ID',
  );
}