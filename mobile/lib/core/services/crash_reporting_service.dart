import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_guard.dart';

final crashReportingServiceProvider =
    Provider<CrashReportingService>((ref) => CrashReportingService());

class CrashReportingService {
  bool get _enabled => FirebaseGuard.isInitialized && !kDebugMode;

  void setUserId(String id) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.setUserIdentifier(id);
  }

  void clearUserId() {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  void log(String message) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.log(message);
  }

  void recordError(dynamic error, StackTrace? stack, {bool fatal = false}) {
    if (!_enabled) {
      debugPrint('Error: $error\n$stack');
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }
}
