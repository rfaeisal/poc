import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/talk_timer.dart';
import '../../features/ptt/providers/ptt_provider.dart';

class HyteraSpeakerBox extends ConsumerStatefulWidget {
  const HyteraSpeakerBox({super.key});

  @override
  ConsumerState<HyteraSpeakerBox> createState() => _HyteraSpeakerBoxState();
}

class _HyteraSpeakerBoxState extends ConsumerState<HyteraSpeakerBox> {
  String? _lastSpeakerCallsign;

  @override
  Widget build(BuildContext context) {
    final ptt = ref.watch(pttProvider);

    final bool isRx =
        !ptt.isTransmitting && ptt.currentSpeakerCallsign != null;
    final bool isTx = ptt.isTransmitting && !ptt.isLocked;
    final bool isLocked = ptt.isTransmitting && ptt.isLocked;
    final bool isActive = isRx || isTx || isLocked;

    if (isRx && ptt.currentSpeakerCallsign != null) {
      _lastSpeakerCallsign = ptt.currentSpeakerCallsign;
    }

    final Color bgColor;
    final Color borderColor;
    final Color callsignColor;
    final String badgeText;
    final Color badgeBg;
    final Color badgeColor;

    if (isLocked) {
      bgColor = const Color(0xFF1A0505);
      borderColor = const Color(0xFFDC2626);
      callsignColor = const Color(0xFFF87171);
      badgeText = 'LOCKED';
      badgeBg = const Color(0xFF1A0505);
      badgeColor = const Color(0xFFFCA5A5);
    } else if (isTx) {
      bgColor = const Color(0xFF140808);
      borderColor = const Color(0xFFDC2626);
      callsignColor = const Color(0xFFF87171);
      badgeText = 'TX';
      badgeBg = const Color(0xFF140808);
      badgeColor = const Color(0xFFF87171);
    } else if (isRx) {
      bgColor = const Color(0xFF041810);
      borderColor = const Color(0xFF0F6E56);
      callsignColor = const Color(0xFF4ADE80);
      badgeText = 'RX';
      badgeBg = const Color(0xFF041810);
      badgeColor = const Color(0xFF4ADE80);
    } else {
      bgColor = const Color(0xFF080D18);
      borderColor = const Color(0xFF1E3A5F);
      callsignColor = _lastSpeakerCallsign != null
          ? const Color(0xFF4A6A8A)
          : const Color(0xFF2A4A6A);
      badgeText = 'IDLE';
      badgeBg = const Color(0xFF0F1E2E);
      badgeColor = const Color(0xFF4A6A8A);
    }

    final String callsign;
    if (isTx || isLocked) {
      callsign = 'SAYA';
    } else if (isRx) {
      callsign = ptt.currentSpeakerCallsign ?? '';
    } else if (_lastSpeakerCallsign != null) {
      callsign = _lastSpeakerCallsign!;
    } else {
      callsign = '---';
    }

    final connStatus = ptt.connectionStatus;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      color: bgColor,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor == const Color(0xFF080D18)
                  ? const Color(0xFF0F2040)
                  : bgColor,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              Icons.person,
              size: 16,
              color: isRx
                  ? const Color(0xFF4ADE80)
                  : (isTx || isLocked)
                      ? const Color(0xFFF87171)
                      : const Color(0xFF2A5A8A),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CALLSIGN',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    color: Color(0xFF4A6A8A),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  callsign,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: callsignColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        border: isActive
                            ? Border.all(
                                color: badgeColor.withValues(alpha: 0.4),
                                width: 1,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 4),
                      TalkTimer(
                        isActive: true,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isRx
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connStatus == ConnectionStatus.connected
                            ? const Color(0xFF4ADE80)
                            : connStatus == ConnectionStatus.connecting
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connStatus == ConnectionStatus.connected
                          ? 'Connected'
                          : connStatus == ConnectionStatus.connecting
                              ? 'Reconnecting'
                              : 'Disconnected',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: connStatus == ConnectionStatus.connected
                            ? const Color(0xFF4A8A6A)
                            : connStatus == ConnectionStatus.connecting
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
