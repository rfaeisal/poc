import 'package:flutter/material.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'shared/widgets/connectivity_banner.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'POC-Pecek',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) => ConnectivityBanner(child: child!),
    );
  }
}
