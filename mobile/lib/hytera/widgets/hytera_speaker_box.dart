import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/talk_timer.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/channels/providers/channel_members_provider.dart';
import '../../features/ptt/providers/ptt_provider.dart';

class HyteraSpeakerBox extends ConsumerWidget {
  const HyteraSpeakerBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ptt = ref.watch(pttProvider);

    final bool isRx =
        !ptt.isTransmitting && ptt.currentSpeakerCallsign != null;
    final bool isTx = ptt.isTransmitting && !ptt.isLocked;
    final bool isLocked = ptt.isTransmitting && ptt.isLocked;
    final bool isActive = isRx || isTx || isLocked;

    final Color bgColor;
    final Color callsignColor;
    final String badgeText;
    final Color badgeBg;
    final Color badgeColor;

    if (isLocked) {
      bgColor = const Color(0xFF1A0505);
      callsignColor = const Color(0xFFF87171);
      badgeText = 'LOCKED';
      badgeBg = const Color(0xFF1A0505);
      badgeColor = const Color(0xFFFCA5A5);
    } else if (isTx) {
      bgColor = const Color(0xFF140808);
      callsignColor = const Color(0xFFF87171);
      badgeText = 'TX';
      badgeBg = const Color(0xFF140808);
      badgeColor = const Color(0xFFF87171);
    } else if (isRx) {
      bgColor = const Color(0xFF041810);
      callsignColor = const Color(0xFF4ADE80);
      badgeText = 'RX';
      badgeBg = const Color(0xFF041810);
      badgeColor = const Color(0xFF4ADE80);
    } else {
      bgColor = const Color(0xFF080D18);
      callsignColor = ptt.lastSpeakerCallsign != null
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
    } else if (ptt.lastSpeakerCallsign != null) {
      callsign = ptt.lastSpeakerCallsign!;
    } else {
      callsign = '---';
    }

    final members = ref.watch(channelMembersProvider).members;
    final auth = ref.watch(authProvider);

    String? speakerName;
    if (isTx || isLocked) {
      speakerName = auth.user?.profile.name;
    } else if (isRx && ptt.currentSpeakerCallsign != null) {
      speakerName = members.values
          .where((m) => m.callsign == ptt.currentSpeakerCallsign)
          .firstOrNull
          ?.name;
    } else if (ptt.lastSpeakerCallsign != null) {
      speakerName = members.values
          .where((m) => m.callsign == ptt.lastSpeakerCallsign)
          .firstOrNull
          ?.name;
    }

    final connStatus = ptt.connectionStatus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        callsign,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: callsignColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
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
                        ),
                      ),
                    ),
                  ],
                ),
                if (speakerName != null)
                  Text(
                    speakerName,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      color: Color(0xFF4A6A8A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    if (isActive) ...[
                      TalkTimer(
                        isActive: true,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isRx
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connStatus == ConnectionStatus.connected
                            ? const Color(0xFF4ADE80)
                            : connStatus == ConnectionStatus.connecting
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      connStatus == ConnectionStatus.connected
                          ? 'OK'
                          : connStatus == ConnectionStatus.connecting
                              ? '...'
                              : 'OFF',
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
