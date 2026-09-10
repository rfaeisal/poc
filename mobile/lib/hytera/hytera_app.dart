import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/auth_side_effects.dart';
import '../shared/widgets/connectivity_banner.dart';
import 'config/hytera_theme.dart';
import 'config/hytera_router.dart';

class HyteraApp extends ConsumerWidget {
  const HyteraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authSideEffectsProvider);

    return MaterialApp.router(
      title: 'POC-PTX',
      debugShowCheckedModeBanner: false,
      theme: HyteraTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: hyteraRouter,
      builder: (context, child) => ConnectivityBanner(child: child!),
    );
  }
}
