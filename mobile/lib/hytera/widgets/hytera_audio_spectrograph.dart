import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class HyteraAudioSpectrograph extends StatefulWidget {
  final bool isTransmitting;
  final bool isReceiving;

  const HyteraAudioSpectrograph({
    super.key,
    this.isTransmitting = false,
    this.isReceiving = false,
  });

  @override
  State<HyteraAudioSpectrograph> createState() =>
      _HyteraAudioSpectrographState();
}

class _HyteraAudioSpectrographState extends State<HyteraAudioSpectrograph> {
  static const _barCount = 20;
  final _random = Random();
  List<double> _heights = List.filled(_barCount, 3);
  Timer? _timer;

  bool get _isActive => widget.isTransmitting || widget.isReceiving;

  @override
  void initState() {
    super.initState();
    if (_isActive) _startAnimation();
  }

  @override
  void didUpdateWidget(covariant HyteraAudioSpectrograph oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive =
        oldWidget.isTransmitting || oldWidget.isReceiving;
    if (_isActive && !wasActive) {
      _startAnimation();
    } else if (!_isActive && wasActive) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _heights = List.generate(
          _barCount,
          (_) => 3.0 + _random.nextDouble() * 13.0,
        );
      });
    });
  }

  void _stopAnimation() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _heights = List.generate(
          _barCount,
          (_) => 2.0 + _random.nextDouble() * 2.0,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color barColor;
    if (widget.isTransmitting) {
      barColor = const Color(0xFFEF4444);
    } else if (widget.isReceiving) {
      barColor = const Color(0xFF1D9E75);
    } else {
      barColor = const Color(0xFF0F2040);
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: const Color(0xFF050810),
      child: Row(
        children: List.generate(_barCount, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.75),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  height: _heights[i],
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(1)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
