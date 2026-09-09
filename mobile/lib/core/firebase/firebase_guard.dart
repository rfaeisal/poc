import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseGuard {
  static bool isInitialized = false;

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isInitialized = true;
      debugPrint('Firebase initialized successfully');
      return true;
    } catch (e) {
      isInitialized = false;
      debugPrint('Firebase initialization failed: $e');
      debugPrint('App will continue without Firebase features');
      return false;
    }
  }
}
