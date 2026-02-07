// Firebase configuration - do not modify.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyC8ckyFHxrXzoh6M7CMI40h6NG_UO8YlbU',
    appId: '1:774400409869:web:76c66cd8bc7693dc407044',
    messagingSenderId: '774400409869',
    projectId: 'wallouapp1',
    authDomain: 'wallouapp1.firebaseapp.com',
    databaseURL: 'https://wallouapp1-default-rtdb.firebaseio.com',
    storageBucket: 'wallouapp1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8ckyFHxrXzoh6M7CMI40h6NG_UO8YlbU',
    appId: '1:774400409869:android:9fe51be4f774f164407044',
    messagingSenderId: '774400409869',
    projectId: 'wallouapp1',
    databaseURL: 'https://wallouapp1-default-rtdb.firebaseio.com',
    storageBucket: 'wallouapp1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8ckyFHxrXzoh6M7CMI40h6NG_UO8YlbU',
    appId: '1:774400409869:ios:1dd268baabbc506c407044',
    messagingSenderId: '774400409869',
    projectId: 'wallouapp1',
    databaseURL: 'https://wallouapp1-default-rtdb.firebaseio.com',
    storageBucket: 'wallouapp1.firebasestorage.app',
    iosBundleId: 'com.extra.wallou',
  );
}
