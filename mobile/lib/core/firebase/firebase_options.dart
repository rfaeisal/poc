// PLACEHOLDER — Replace with output of `flutterfire configure`
//
// To configure Firebase for this project:
// 1. Install FlutterFire CLI: dart pub global activate flutterfire_cli
// 2. Create a Firebase project at https://console.firebase.google.com
// 3. Run: flutterfire configure --project=<your-project-id>
// 4. This file will be overwritten with real values

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY_HERE',
    appId: 'YOUR_APP_ID_HERE',
    messagingSenderId: 'YOUR_SENDER_ID_HERE',
    projectId: 'YOUR_PROJECT_ID_HERE',
    storageBucket: 'YOUR_STORAGE_BUCKET_HERE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY_HERE',
    appId: 'YOUR_APP_ID_HERE',
    messagingSenderId: 'YOUR_SENDER_ID_HERE',
    projectId: 'YOUR_PROJECT_ID_HERE',
    storageBucket: 'YOUR_STORAGE_BUCKET_HERE',
    iosBundleId: 'com.fakhriez.pocPecek',
  );
}
