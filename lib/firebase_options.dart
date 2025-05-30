// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9JQ1UK0mW2Gy_IvIEVBmw8zP3owmNfWs',
    appId: '1:299915224002:web:f59aab4cfe29e827dfac5b',
    messagingSenderId: '299915224002',
    projectId: 'elearning-61eff',
    authDomain: 'elearning-61eff.firebaseapp.com',
    storageBucket: 'elearning-61eff.firebasestorage.app',
    measurementId: 'G-EBVNV2K4Q2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8IKsCOV2bqP__OKdtnAjK3V8Vt-mu7r0',
    appId: '1:299915224002:android:44b62d0717e2e5d4dfac5b',
    messagingSenderId: '299915224002',
    projectId: 'elearning-61eff',
    storageBucket: 'elearning-61eff.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDSrOZNIroPT_oo34pzRNsCYZSLeeKcokM',
    appId: '1:299915224002:ios:d2424a0ae8bb8625dfac5b',
    messagingSenderId: '299915224002',
    projectId: 'elearning-61eff',
    storageBucket: 'elearning-61eff.firebasestorage.app',
    iosBundleId: 'com.example.eLearning',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDSrOZNIroPT_oo34pzRNsCYZSLeeKcokM',
    appId: '1:299915224002:ios:d2424a0ae8bb8625dfac5b',
    messagingSenderId: '299915224002',
    projectId: 'elearning-61eff',
    storageBucket: 'elearning-61eff.firebasestorage.app',
    iosBundleId: 'com.example.eLearning',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD9JQ1UK0mW2Gy_IvIEVBmw8zP3owmNfWs',
    appId: '1:299915224002:web:012c49109a3553eddfac5b',
    messagingSenderId: '299915224002',
    projectId: 'elearning-61eff',
    authDomain: 'elearning-61eff.firebaseapp.com',
    storageBucket: 'elearning-61eff.firebasestorage.app',
    measurementId: 'G-P3Y0QX6LYL',
  );
}
