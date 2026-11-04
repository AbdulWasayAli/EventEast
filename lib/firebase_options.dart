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
    apiKey: 'AIzaSyCG1_sanM3re4NsFMe7M2LweX0G91lU9Bc',
    appId: '1:283002300630:web:a629e4cadc70b483ba0177',
    messagingSenderId: '283002300630',
    projectId: 'eventease-c7e98',
    authDomain: 'eventease-c7e98.firebaseapp.com',
    storageBucket: 'eventease-c7e98.firebasestorage.app',
    measurementId: 'G-1YB3Y2BX8J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBweYHTHHZV2Hoj1jssL6gOBG4UuJwodwM',
    appId: '1:283002300630:android:11291bf599cf4133ba0177',
    messagingSenderId: '283002300630',
    projectId: 'eventease-c7e98',
    storageBucket: 'eventease-c7e98.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBUuKQu6IsNA7AiF6QrRQEPV8RY3Zmu3eU',
    appId: '1:283002300630:ios:9a6a6021ca5c22d8ba0177',
    messagingSenderId: '283002300630',
    projectId: 'eventease-c7e98',
    storageBucket: 'eventease-c7e98.firebasestorage.app',
    iosBundleId: 'com.example.eventEase',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBUuKQu6IsNA7AiF6QrRQEPV8RY3Zmu3eU',
    appId: '1:283002300630:ios:9a6a6021ca5c22d8ba0177',
    messagingSenderId: '283002300630',
    projectId: 'eventease-c7e98',
    storageBucket: 'eventease-c7e98.firebasestorage.app',
    iosBundleId: 'com.example.eventEase',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCG1_sanM3re4NsFMe7M2LweX0G91lU9Bc',
    appId: '1:283002300630:web:7b439ad7f09186d3ba0177',
    messagingSenderId: '283002300630',
    projectId: 'eventease-c7e98',
    authDomain: 'eventease-c7e98.firebaseapp.com',
    storageBucket: 'eventease-c7e98.firebasestorage.app',
    measurementId: 'G-L1FTZ4P7MR',
  );
}
