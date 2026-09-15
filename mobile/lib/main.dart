import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_guard.dart';
import 'core/services/foreground_service.dart';
import 'flavors/flavor_config.dart';
import 'hytera/hytera_app.dart';
import 'ksun/ksun_app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class _KsunHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  if (FlavorConfig.isKsun) {
    HttpOverrides.global = _KsunHttpOverrides();
  }

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await PttForegroundService.init();

    final firebaseReady = await FirebaseGuard.initialize();

    if (firebaseReady) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } else {
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}');
      };
    }

    if (FlavorConfig.isKsun) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    runApp(ProviderScope(
      child: FlavorConfig.isHytera
          ? const HyteraApp()
          : FlavorConfig.isKsun
              ? const KsunApp()
              : const App(),
    ));
  }, (error, stack) {
    if (FirebaseGuard.isInitialized) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    debugPrint('Uncaught error: $error\n$stack');
  });
}
