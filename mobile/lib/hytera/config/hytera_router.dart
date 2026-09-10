import 'package:go_router/go_router.dart';

import '../screens/hytera_login_screen.dart';
import '../screens/hytera_main_screen.dart';
import '../screens/hytera_channel_screen.dart';
import '../screens/hytera_channel_list_screen.dart';
import '../screens/hytera_echo_test_screen.dart';
import '../screens/hytera_pengaturan_screen.dart';

final hyteraRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const HyteraLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HyteraMainScreen(child: child),
      routes: [
        GoRoute(
          path: '/channel',
          builder: (context, state) => const HyteraChannelScreen(),
        ),
GoRoute(
          path: '/pengaturan',
          builder: (context, state) => const HyteraPengaturanScreen(),
        ),
        GoRoute(
          path: '/echo-test',
          builder: (context, state) => const HyteraEchoTestScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/channel-list',
      builder: (context, state) => const HyteraChannelListScreen(),
    ),
  ],
);
