import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ptt_provider.dart';

class PttButton extends ConsumerWidget {
  const PttButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ptt = ref.watch(pttProvider);
    final notifier = ref.read(pttProvider.notifier);

    final Color buttonColor;
    final String label;
    final IconData icon;

    if (ptt.isTransmitting) {
      buttonColor = Theme.of(context).colorScheme.error;
      label = ptt.isLocked ? 'LOCKED — Tap to Stop' : 'TRANSMITTING';
      icon = Icons.mic;
    } else if (ptt.isBusy) {
      buttonColor = Colors.grey;
      label = 'Channel Busy';
      icon = Icons.mic_off;
    } else {
      buttonColor = Theme.of(context).colorScheme.primary;
      label = 'Hold to Talk';
      icon = Icons.mic_none;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: ptt.isBusy || ptt.isLocked
              ? null
              : (_) {
                  HapticFeedback.heavyImpact();
                  notifier.startTransmit();
                },
          onLongPressEnd: ptt.isLocked
              ? null
              : (_) {
                  notifier.stopTransmit();
                },
          onDoubleTap: ptt.isBusy ? null : () => notifier.toggleLock(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
              boxShadow: ptt.isTransmitting
                  ? [
                      BoxShadow(
                        color: buttonColor.withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: buttonColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 56,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: buttonColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        if (!ptt.isTransmitting && !ptt.isBusy)
          Text(
            'Double tap to lock',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}
