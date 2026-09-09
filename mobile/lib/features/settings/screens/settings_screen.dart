import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/battery_optimization_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Profile'),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(auth.user?.profile.callsign ?? '-'),
            subtitle: Text(auth.user?.profile.name ?? '-'),
          ),
          const Divider(),
          _SectionHeader(title: 'Audio'),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Audio Settings'),
            subtitle: Text(
              'VOX: ${settings.voxEnabled ? "ON" : "OFF"}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/audio'),
          ),
          const Divider(),
          _SectionHeader(title: 'Bluetooth'),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Bluetooth PTT'),
            subtitle: Text(
              settings.bluetoothDeviceName ?? 'Not connected',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/bluetooth'),
          ),
          const Divider(),
          _SectionHeader(title: 'Location'),
          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined),
            title: const Text('Share Location'),
            subtitle: const Text('Show your position on the map'),
            value: settings.locationSharing,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setLocationSharing(v),
          ),
          const Divider(),
          _SectionHeader(title: 'Device'),
          FutureBuilder<int>(
            future: Battery().batteryLevel,
            builder: (context, snapshot) {
              return ListTile(
                leading: const Icon(Icons.battery_std),
                title: const Text('Battery'),
                subtitle: Text(
                  snapshot.hasData ? '${snapshot.data}%' : 'Loading...',
                ),
              );
            },
          ),
          FutureBuilder<bool>(
            future:
                BatteryOptimizationService.isIgnoringBatteryOptimizations(),
            builder: (context, snapshot) {
              final isUnrestricted = snapshot.data ?? false;
              return ListTile(
                leading: const Icon(Icons.battery_saver),
                title: const Text('Battery Optimization'),
                subtitle: Text(
                  isUnrestricted ? 'Unrestricted' : 'Restricted — tap to fix',
                ),
                trailing: isUnrestricted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: isUnrestricted
                    ? null
                    : () async {
                        await BatteryOptimizationService
                            .requestIgnoreBatteryOptimizations();
                        if (context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                      },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Device Info'),
            subtitle: const Text('Diagnostics & debug info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/device'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
