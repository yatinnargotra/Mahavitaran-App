// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBgh9_uxQw4HRsNfN0mkoiwihoPADfcu2o',
    appId: '1:80707326377:web:3ff5510a8c038e13be74b8',
    messagingSenderId: '80707326377',
    projectId: 'fluttermyloginpage',
    authDomain: 'fluttermyloginpage.firebaseapp.com',
    storageBucket: 'fluttermyloginpage.appspot.com',
    measurementId: 'G-D2ZQV7X2TC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOqay876ugz9K7Hi4LNCwDHAhw9Ia3hDE',
    appId: '1:80707326377:android:b08e7ddddcfc109abe74b8',
    messagingSenderId: '80707326377',
    projectId: 'fluttermyloginpage',
    storageBucket: 'fluttermyloginpage.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvYQEkMABJ_-Du9yKrUjz71AzaFXpnaCs',
    appId: '1:80707326377:ios:99c164a492a76317be74b8',
    messagingSenderId: '80707326377',
    projectId: 'fluttermyloginpage',
    storageBucket: 'fluttermyloginpage.appspot.com',
    iosBundleId: 'com.example.myloginpage',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDvYQEkMABJ_-Du9yKrUjz71AzaFXpnaCs',
    appId: '1:80707326377:ios:99c164a492a76317be74b8',
    messagingSenderId: '80707326377',
    projectId: 'fluttermyloginpage',
    storageBucket: 'fluttermyloginpage.appspot.com',
    iosBundleId: 'com.example.myloginpage',
  );
}
