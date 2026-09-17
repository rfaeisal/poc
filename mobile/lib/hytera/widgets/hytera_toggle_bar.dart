import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../features/channels/providers/channel_members_provider.dart';
import '../../features/settings/providers/settings_provider.dart';

class HyteraToggleBar extends ConsumerStatefulWidget {
  const HyteraToggleBar({super.key});

  @override
  ConsumerState<HyteraToggleBar> createState() => _HyteraToggleBarState();
}

class _HyteraToggleBarState extends ConsumerState<HyteraToggleBar> {
  int? _latencyMs;
  Timer? _pingTimer;
  late final String _pingHost;
  late final int _pingPort;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    _pingHost = uri.host;
    _pingPort = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    _pingServer();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pingServer();
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _pingServer() async {
    try {
      final sw = Stopwatch()..start();
      final socket = await Socket.connect(
        _pingHost,
        _pingPort,
        timeout: const Duration(seconds: 5),
      );
      sw.stop();
      socket.destroy();
      if (mounted) setState(() => _latencyMs = sw.elapsedMilliseconds);
    } catch (_) {
      if (mounted) setState(() => _latencyMs = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final mqttConnected = ref.watch(mqttConnectedProvider).valueOrNull ?? false;

    final bool voxOn = settings.voxEnabled;
    final bool btOn = settings.bluetoothDeviceName != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MqttIcon(isConnected: mqttConnected),
        const SizedBox(width: 6),
        _LatencyChip(latencyMs: _latencyMs),
        const SizedBox(width: 6),
        _ToggleChip(
          label: 'VOX',
          isOn: voxOn,
          onTap: () => notifier.setVoxEnabled(!voxOn),
        ),
        const SizedBox(width: 6),
        _ToggleChip(
          label: 'BT',
          isOn: btOn,
          onTap: null,
        ),
      ],
    );
  }
}

class _MqttIcon extends StatelessWidget {
  final bool isConnected;
  const _MqttIcon({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isConnected
              ? const Color(0xFF1E5A2A)
              : const Color(0xFF5A1E1E),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(
        isConnected ? Icons.cloud_done : Icons.cloud_off,
        size: 10,
        color: isConnected
            ? const Color(0xFF4ADE80)
            : const Color(0xFFEF4444),
      ),
    );
  }
}

class _LatencyChip extends StatelessWidget {
  final int? latencyMs;
  const _LatencyChip({required this.latencyMs});

  Color get _color {
    if (latencyMs == null) return const Color(0xFF4A6A8A);
    if (latencyMs! < 200) return const Color(0xFF4ADE80);
    if (latencyMs! < 500) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  Color get _borderColor {
    if (latencyMs == null) return const Color(0xFF1E2A3A);
    if (latencyMs! < 200) return const Color(0xFF1E5A2A);
    if (latencyMs! < 500) return const Color(0xFF5A4A1E);
    return const Color(0xFF5A1E1E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        latencyMs != null ? '${latencyMs}ms' : '--',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          color: _color,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback? onTap;

  const _ToggleChip({
    required this.label,
    required this.isOn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isOn
                ? const Color(0xFF1E5A2A)
                : const Color(0xFF1E2A3A),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7,
            color: isOn
                ? const Color(0xFF4ADE80)
                : const Color(0xFF4A6A8A),
          ),
        ),
      ),
    );
  }
}
