import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/auth_side_effects.dart';
import '../shared/widgets/connectivity_banner.dart';
import 'config/ksun_theme.dart';
import 'config/ksun_router.dart';

class KsunApp extends ConsumerWidget {
  const KsunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authSideEffectsProvider);

    return MaterialApp.router(
      title: 'POC-SMART',
      debugShowCheckedModeBanner: false,
      theme: KsunTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: ksunRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.5),
          ),
          child: ConnectivityBanner(child: child!),
        );
      },
    );
  }
}
