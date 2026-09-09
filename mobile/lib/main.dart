import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PttForegroundService.init();
  runApp(const ProviderScope(child: App()));
}
