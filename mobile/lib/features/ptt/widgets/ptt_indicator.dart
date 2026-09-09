import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/talk_timer.dart';
import '../providers/ptt_provider.dart';

class PttIndicator extends ConsumerWidget {
  const PttIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ptt = ref.watch(pttProvider);

    final String speakerLabel;
    final bool isActive;

    if (ptt.isTransmitting) {
      speakerLabel = 'You are transmitting';
      isActive = true;
    } else if (ptt.currentSpeakerCallsign != null) {
      speakerLabel = '${ptt.currentSpeakerCallsign} is transmitting';
      isActive = true;
    } else {
      speakerLabel = 'Channel idle';
      isActive = false;
    }

    final initial = ptt.isTransmitting
        ? 'YOU'
        : ptt.currentSpeakerCallsign?.substring(0, 2).toUpperCase() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedRing(
          isActive: isActive,
          isSelf: ptt.isTransmitting,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: isActive
                ? Text(
                    initial,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  )
                : Icon(
                    Icons.radio,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          speakerLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        TalkTimer(isActive: isActive),
        if (ptt.connectionStatus != ConnectionStatus.connected) ...[
          const SizedBox(height: 4),
          _ConnectionBadge(status: ptt.connectionStatus),
        ],
      ],
    );
  }
}

class _AnimatedRing extends StatefulWidget {
  final bool isActive;
  final bool isSelf;
  final Widget child;

  const _AnimatedRing({
    required this.isActive,
    required this.isSelf,
    required this.child,
  });

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _AnimatedRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelf
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: _opacityAnim.value),
                        width: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (widget.isActive)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      ConnectionStatus.connecting => ('Reconnecting...', Colors.orange),
      ConnectionStatus.disconnected => ('Disconnected', Colors.red),
      ConnectionStatus.connected => ('Connected', Colors.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
