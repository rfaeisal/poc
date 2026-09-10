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
    final String? subLabel;
    final double opacity;

    if (ptt.isTransmitting && ptt.isLocked) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFF5A0A0A);
      iconColor = const Color(0xFFEF4444);
      label = 'LOCKED';
      subLabel = 'TAP TO STOP';
      opacity = 1.0;
    } else if (ptt.isTransmitting) {
      borderColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFF4A0808);
      iconColor = const Color(0xFFEF4444);
      label = 'TX ON';
      subLabel = 'ON AIR';
      opacity = 1.0;
    } else if (ptt.isBusy) {
      borderColor = const Color(0xFF1E4A8A);
      bgColor = const Color(0xFF0F2040);
      iconColor = const Color(0xFF4A9EFF);
      label = 'CHANNEL';
      subLabel = 'BUSY';
      opacity = 0.4;
    } else {
      borderColor = const Color(0xFF1E4A8A);
      bgColor = const Color(0xFF0F2040);
      iconColor = const Color(0xFF4A9EFF);
      label = 'PTT';
      subLabel = null;
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 18, color: iconColor),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      color: ptt.isTransmitting
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4A6A8A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 6,
                        color: ptt.isTransmitting
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF4A6A8A),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isIdle) ...[
          const SizedBox(height: 4),
          const Text(
            'Tahan bicara · tahan >2dtk lock',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 6.5,
              color: Color(0xFF2A4A6A),
            ),
          ),
        ],
      ],
    );
  }
}
