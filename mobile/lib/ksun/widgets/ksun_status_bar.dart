import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

class KsunStatusBar extends StatefulWidget {
  final bool isMqttConnected;

  const KsunStatusBar({
    super.key,
    this.isMqttConnected = false,
  });

  @override
  State<KsunStatusBar> createState() => _KsunStatusBarState();
}

class _KsunStatusBarState extends State<KsunStatusBar> {
  final _battery = Battery();
  static const _platform = MethodChannel('com.fakhriez.poc_ptx/kiosk');
  int _batteryLevel = 0;
  int? _latencyMs;
  int? _signalDbm;
  Timer? _pingTimer;
  late final String _pingHost;
  late final int _pingPort;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    _pingHost = uri.host;
    _pingPort = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    _refreshAll();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    _loadBattery();
    _pingServer();
    _loadSignal();
  }

  Future<void> _loadBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  Future<void> _loadSignal() async {
    try {
      final dbm = await _platform.invokeMethod<int>('getSignalStrength');
      if (mounted) setState(() => _signalDbm = dbm);
    } catch (_) {
      if (mounted) setState(() => _signalDbm = null);
    }
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

  IconData _signalIcon() {
    if (_signalDbm == null) return Icons.signal_cellular_off;
    if (_signalDbm! > -70) return Icons.signal_cellular_4_bar;
    if (_signalDbm! > -80) return Icons.signal_cellular_alt_2_bar;
    if (_signalDbm! > -100) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_cellular_0_bar;
  }

  Color _signalColor() {
    if (_signalDbm == null) return const Color(0xFF516079);
    if (_signalDbm! > -80) return const Color(0xFF4ADE80);
    if (_signalDbm! > -100) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  Color _batteryColor() {
    if (_batteryLevel > 20) return const Color(0xFF4ADE80);
    if (_batteryLevel > 10) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final latencyColor = _latencyMs == null
        ? const Color(0xFF516079)
        : _latencyMs! < 200
            ? const Color(0xFF4ADE80)
            : _latencyMs! < 500
                ? const Color(0xFFFBBF24)
                : const Color(0xFFEF4444);

    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 3),
      decoration: const BoxDecoration(
        color: Color(0xFF060910),
        border: Border(
          bottom: BorderSide(color: Color(0xFF0F1E2E), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _signalIcon(),
                size: 8,
                color: _signalColor(),
              ),
              const SizedBox(width: 1),
              Text(
                _signalDbm != null ? '$_signalDbm' : '--',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  color: _signalColor(),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isMqttConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 7,
                color: widget.isMqttConnected
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 2),
              Text(
                _latencyMs != null ? '${_latencyMs}ms' : '--',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  color: latencyColor,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_batteryLevel%',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  color: _batteryColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
