import 'package:go_router/go_router.dart';

import '../screens/ksun_login_screen.dart';
import '../screens/ksun_main_screen.dart';
import '../screens/ksun_channel_screen.dart';
import '../screens/ksun_channel_list_screen.dart';
import '../screens/ksun_echo_test_screen.dart';
import '../screens/ksun_pengaturan_screen.dart';

final ksunRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const KsunLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => KsunMainScreen(child: child),
      routes: [
        GoRoute(
          path: '/channel',
          builder: (context, state) => const KsunChannelScreen(),
        ),
        GoRoute(
          path: '/pengaturan',
          builder: (context, state) => const KsunPengaturanScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/echo-test',
      builder: (context, state) => const KsunEchoTestScreen(),
    ),
    GoRoute(
      path: '/channel-list',
      builder: (context, state) => const KsunChannelListScreen(),
    ),
  ],
);
