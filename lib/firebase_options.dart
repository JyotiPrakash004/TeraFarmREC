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
    apiKey: 'AIzaSyD8Le9F1H_Bki5vyavO3W5mS053oFpDMh8',
    appId: '1:439912812950:web:19eb54300d6aef59a24db7',
    messagingSenderId: '439912812950',
    projectId: 'terafarm-3ab30',
    authDomain: 'terafarm-3ab30.firebaseapp.com',
    storageBucket: 'terafarm-3ab30.firebasestorage.app',
    measurementId: 'G-F1GXSS5NMZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1usH29mDRGePwylJGHC9z2TVU69uAe0M',
    appId: '1:439912812950:android:5345d59a6c3a16f9a24db7',
    messagingSenderId: '439912812950',
    projectId: 'terafarm-3ab30',
    storageBucket: 'terafarm-3ab30.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqN03Nk6KAt65MUiA8QaN911gPYZp4tVY',
    appId: '1:439912812950:ios:7db06c8029a1e195a24db7',
    messagingSenderId: '439912812950',
    projectId: 'terafarm-3ab30',
    storageBucket: 'terafarm-3ab30.firebasestorage.app',
    iosBundleId: 'com.example.terafarm1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDqN03Nk6KAt65MUiA8QaN911gPYZp4tVY',
    appId: '1:439912812950:ios:7db06c8029a1e195a24db7',
    messagingSenderId: '439912812950',
    projectId: 'terafarm-3ab30',
    storageBucket: 'terafarm-3ab30.firebasestorage.app',
    iosBundleId: 'com.example.terafarm1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD8Le9F1H_Bki5vyavO3W5mS053oFpDMh8',
    appId: '1:439912812950:web:176a307247feac31a24db7',
    messagingSenderId: '439912812950',
    projectId: 'terafarm-3ab30',
    authDomain: 'terafarm-3ab30.firebaseapp.com',
    storageBucket: 'terafarm-3ab30.firebasestorage.app',
    measurementId: 'G-22NGDWGVJG',
  );

}