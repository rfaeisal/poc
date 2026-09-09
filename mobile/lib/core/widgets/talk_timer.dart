import 'dart:async';

import 'package:flutter/material.dart';

class TalkTimer extends StatefulWidget {
  final bool isActive;
  final TextStyle? style;

  const TalkTimer({super.key, required this.isActive, this.style});

  @override
  State<TalkTimer> createState() => _TalkTimerState();
}

class _TalkTimerState extends State<TalkTimer> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void didUpdateWidget(covariant TalkTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _seconds = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    } else if (!widget.isActive && oldWidget.isActive) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && _seconds == 0) return const SizedBox.shrink();

    return Text(
      _formatted,
      style: widget.style ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
    );
  }
}
