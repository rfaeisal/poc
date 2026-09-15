import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class KsunAudioSpectrograph extends StatefulWidget {
  final bool isTransmitting;
  final bool isReceiving;

  const KsunAudioSpectrograph({
    super.key,
    this.isTransmitting = false,
    this.isReceiving = false,
  });

  @override
  State<KsunAudioSpectrograph> createState() =>
      _KsunAudioSpectrographState();
}

class _KsunAudioSpectrographState extends State<KsunAudioSpectrograph> {
  static const _barCount = 16;
  final _random = Random();
  List<double> _heights = List.filled(_barCount, 2);
  Timer? _timer;

  bool get _isActive => widget.isTransmitting || widget.isReceiving;

  @override
  void initState() {
    super.initState();
    if (_isActive) _startAnimation();
  }

  @override
  void didUpdateWidget(covariant KsunAudioSpectrograph oldWidget) {
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
          (_) => 2.0 + _random.nextDouble() * 7.0,
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
          (_) => 1.0 + _random.nextDouble() * 1.5,
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
      height: 11,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      color: const Color(0xFF050810),
      child: Row(
        children: List.generate(_barCount, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
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
