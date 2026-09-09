import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/channels/models/channel.dart';
import '../features/channels/screens/channel_detail_screen.dart';
import '../features/channels/screens/channel_list_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/settings/screens/audio_settings_screen.dart';
import '../features/settings/screens/bluetooth_settings_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/channels',
      builder: (context, state) => const ChannelListScreen(),
    ),
    GoRoute(
      path: '/channels/:id/ptt',
      builder: (context, state) {
        final channelId = state.pathParameters['id']!;
        final joinResult = state.extra as JoinChannelResult?;
        return ChannelDetailScreen(
          channelId: channelId,
          joinResult: joinResult,
        );
      },
    ),
    GoRoute(
      path: '/channels/:id/map',
      builder: (context, state) {
        final channelId = state.pathParameters['id']!;
        return MapScreen(channelId: channelId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/audio',
      builder: (context, state) => const AudioSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/bluetooth',
      builder: (context, state) => const BluetoothSettingsScreen(),
    ),
  ],
);
