import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/battery_optimization_service.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/services/push_notification_service.dart';

class DeviceInfoScreen extends ConsumerWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Info')),
      body: FutureBuilder<_DiagnosticData>(
        future: _loadData(ref),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(title: 'App'),
              _InfoTile(label: 'Version', value: data.appVersion),
              _InfoTile(label: 'Build', value: data.appBuild),
              const Divider(height: 24),
              _Section(title: 'Device'),
              _InfoTile(label: 'Device ID', value: data.deviceId),
              _InfoTile(label: 'Model', value: data.model),
              _InfoTile(label: 'OS', value: data.osVersion),
              _InfoTile(label: 'Platform', value: data.platform),
              const Divider(height: 24),
              _Section(title: 'Battery'),
              _InfoTile(
                  label: 'Level', value: '${data.batteryLevel}%'),
              _InfoTile(
                label: 'Optimization',
                value: data.batteryOptimized ? 'Unrestricted' : 'Restricted',
                valueColor: data.batteryOptimized ? Colors.green : Colors.orange,
              ),
              const Divider(height: 24),
              _Section(title: 'Network'),
              _InfoTile(
                  label: 'Connection',
                  value: data.connectivity),
              const Divider(height: 24),
              _Section(title: 'Push Notifications'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('FCM Token'),
                subtitle: Text(
                  data.fcmToken ?? 'Not available (Firebase not configured)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: data.fcmToken != null
                    ? IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: data.fcmToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('FCM token copied')),
                          );
                        },
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_DiagnosticData> _loadData(WidgetRef ref) async {
    final deviceInfo = await DeviceInfoService.getDeviceInfo();
    final batteryLevel = await Battery().batteryLevel;
    final batteryOptimized =
        await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    final connectivityResult = await Connectivity().checkConnectivity();
    final fcmToken =
        await ref.read(pushNotificationServiceProvider).getToken();

    String connectivity = 'Unknown';
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      connectivity = 'WiFi';
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      connectivity = 'Mobile Data';
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      connectivity = 'Offline';
    }

    return _DiagnosticData(
      deviceId: deviceInfo.deviceId,
      model: deviceInfo.model,
      osVersion: deviceInfo.osVersion,
      platform: deviceInfo.platform,
      appVersion: deviceInfo.appVersion,
      appBuild: deviceInfo.appBuildNumber,
      batteryLevel: batteryLevel,
      batteryOptimized: batteryOptimized,
      connectivity: connectivity,
      fcmToken: fcmToken,
    );
  }
}

class _DiagnosticData {
  final String deviceId;
  final String model;
  final String osVersion;
  final String platform;
  final String appVersion;
  final String appBuild;
  final int batteryLevel;
  final bool batteryOptimized;
  final String connectivity;
  final String? fcmToken;

  const _DiagnosticData({
    required this.deviceId,
    required this.model,
    required this.osVersion,
    required this.platform,
    required this.appVersion,
    required this.appBuild,
    required this.batteryLevel,
    required this.batteryOptimized,
    required this.connectivity,
    this.fcmToken,
  });
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
