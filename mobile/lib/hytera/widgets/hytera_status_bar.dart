import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
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
  Timer? _pingTimer;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    validateStatus: (_) => true,
  ));

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _dio.close();
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
      await _dio.head(AppConfig.apiBaseUrl);
      sw.stop();
      if (mounted) setState(() => _latencyMs = sw.elapsedMilliseconds);
    } catch (_) {
      if (mounted) setState(() => _latencyMs = null);
    }
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
      height: 20,
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
          _StatusItem(
            text: _signalDbm != null ? '📶 $_signalDbm dBm' : '📶 -- dBm',
            color: _signalDbm == null
                ? const Color(0xFF516079)
                : _signalDbm! > -80
                    ? const Color(0xFF4ADE80)
                    : _signalDbm! > -100
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFEF4444),
          ),
          _StatusItem(
            text: '⬡ MQTT',
            color: widget.isMqttConnected
                ? const Color(0xFF4DB8FF)
                : const Color(0xFF516079),
          ),
          _StatusItem(
            text: _latencyMs != null ? '${_latencyMs}ms' : '--ms',
            color: latencyColor,
          ),
          _StatusItem(
            text: '🔋 $_batteryLevel%',
            color: const Color(0xFF4ADE80),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
