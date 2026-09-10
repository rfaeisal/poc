import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class HyteraStatusBar extends StatefulWidget {
  final bool isMqttConnected;
  final int? latencyMs;

  const HyteraStatusBar({
    super.key,
    this.isMqttConnected = false,
    this.latencyMs,
  });

  @override
  State<HyteraStatusBar> createState() => _HyteraStatusBarState();
}

class _HyteraStatusBarState extends State<HyteraStatusBar> {
  final _battery = Battery();
  int _batteryLevel = 0;

  @override
  void initState() {
    super.initState();
    _loadBattery();
  }

  Future<void> _loadBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
            text: '📶 -88 dBm',
            color: const Color(0xFF4ADE80),
          ),
          _StatusItem(
            text: '⬡ MQTT',
            color: widget.isMqttConnected
                ? const Color(0xFF4DB8FF)
                : const Color(0xFF516079),
          ),
          _StatusItem(
            text: widget.latencyMs != null ? '${widget.latencyMs}ms' : '--ms',
            color: const Color(0xFF94A3B8),
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
