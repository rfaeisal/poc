import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

class HyteraStatusBar extends StatefulWidget {
  final bool isMqttConnected;

  const HyteraStatusBar({
    super.key,
    this.isMqttConnected = false,
  });

  @override
  State<HyteraStatusBar> createState() => _HyteraStatusBarState();
}

class _HyteraStatusBarState extends State<HyteraStatusBar> {
  final _battery = Battery();
  static const _platform = MethodChannel('com.fakhriez.poc_ptx/kiosk');
  int _batteryLevel = 0;
  int? _latencyMs;
  int? _signalDbm;
  int? _signalLevel;
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
      final result = await _platform.invokeMethod<Map>('getSignalStrength');
      if (result != null && mounted) {
        setState(() {
          _signalDbm = result['dbm'] as int?;
          _signalLevel = result['level'] as int?;
        });
      } else if (mounted) {
        setState(() {
          _signalDbm = null;
          _signalLevel = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _signalDbm = null; _signalLevel = null; });
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
    if (_signalLevel == null) return Icons.signal_cellular_off;
    switch (_signalLevel!) {
      case 4: return Icons.signal_cellular_4_bar;
      case 3: return Icons.signal_cellular_alt;
      case 2: return Icons.signal_cellular_alt_2_bar;
      case 1: return Icons.signal_cellular_alt_1_bar;
      default: return Icons.signal_cellular_0_bar;
    }
  }

  Color _signalColor() {
    if (_signalLevel == null) return const Color(0xFF516079);
    if (_signalLevel! >= 3) return const Color(0xFF4ADE80);
    if (_signalLevel! >= 2) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  IconData _batteryIcon() {
    if (_batteryLevel > 90) return Icons.battery_full;
    if (_batteryLevel > 70) return Icons.battery_6_bar;
    if (_batteryLevel > 50) return Icons.battery_5_bar;
    if (_batteryLevel > 30) return Icons.battery_3_bar;
    if (_batteryLevel > 15) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
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
                size: 14,
                color: _signalColor(),
              ),
              const SizedBox(width: 2),
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
                size: 12,
                color: widget.isMqttConnected
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 3),
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
              const SizedBox(width: 2),
              Icon(
                _batteryIcon(),
                size: 16,
                color: _batteryColor(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

