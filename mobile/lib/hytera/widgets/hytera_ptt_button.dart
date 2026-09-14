import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ptt/providers/ptt_provider.dart';

class HyteraPttButton extends ConsumerWidget {
  const HyteraPttButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ptt = ref.watch(pttProvider);
    final notifier = ref.read(pttProvider.notifier);

    final Color borderColor;
    final Color bgColor;
    final Color iconColor;
    final String label;
    final double opacity;

    if (ptt.isTransmitting && ptt.isLocked) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFF5A0A0A);
      iconColor = const Color(0xFFEF4444);
      label = 'LOCKED';
      opacity = 1.0;
    } else if (ptt.isTransmitting) {
      borderColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFF4A0808);
      iconColor = const Color(0xFFEF4444);
      label = 'TX ON';
      opacity = 1.0;
    } else if (ptt.isBusy) {
      borderColor = const Color(0xFF1E4A8A);
      bgColor = const Color(0xFF0F2040);
      iconColor = const Color(0xFF4A9EFF);
      label = 'CHANNEL';
      opacity = 0.4;
    } else {
      borderColor = const Color(0xFF1E4A8A);
      bgColor = const Color(0xFF0F2040);
      iconColor = const Color(0xFF4A9EFF);
      label = 'PTT';
      opacity = 1.0;
    }

    final bool isIdle = !ptt.isTransmitting && !ptt.isBusy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTapDown: ptt.isBusy
                ? null
                : ptt.isLocked
                    ? (_) {
                        notifier.stopTransmit();
                      }
                    : (_) {
                        HapticFeedback.heavyImpact();
                        notifier.startTransmit();
                      },
            onTapUp: ptt.isBusy || ptt.isLocked
                ? null
                : (_) {
                    notifier.stopTransmit();
                  },
            onTapCancel: ptt.isBusy || ptt.isLocked
                ? null
                : () {
                    notifier.stopTransmit();
                  },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Icon(Icons.mic, size: 28, color: iconColor),
            ),
          ),
        ),
        if (!isIdle)
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: ptt.isTransmitting
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF4A6A8A),
            ),
          ),
      ],
    );
  }
}
