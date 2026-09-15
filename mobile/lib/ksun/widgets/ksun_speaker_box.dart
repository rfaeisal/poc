import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/talk_timer.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/channels/providers/channel_members_provider.dart';
import '../../features/ptt/providers/ptt_provider.dart';

class KsunSpeakerBox extends ConsumerWidget {
  const KsunSpeakerBox({super.key});

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
    final Color badgeColor;

    if (isLocked) {
      bgColor = const Color(0xFF1A0505);
      callsignColor = const Color(0xFFF87171);
      badgeText = 'LCK';
      badgeColor = const Color(0xFFFCA5A5);
    } else if (isTx) {
      bgColor = const Color(0xFF140808);
      callsignColor = const Color(0xFFF87171);
      badgeText = 'TX';
      badgeColor = const Color(0xFFF87171);
    } else if (isRx) {
      bgColor = const Color(0xFF041810);
      callsignColor = const Color(0xFF4ADE80);
      badgeText = 'RX';
      badgeColor = const Color(0xFF4ADE80);
    } else {
      bgColor = const Color(0xFF080D18);
      callsignColor = ptt.lastSpeakerCallsign != null
          ? const Color(0xFF4A6A8A)
          : const Color(0xFF2A4A6A);
      badgeText = 'IDLE';
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

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 14, bottom: 2),
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
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: callsignColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2),
                      decoration: BoxDecoration(
                        border: isActive
                            ? Border.all(
                                color: badgeColor.withValues(alpha: 0.4),
                                width: 1,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(1),
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
                    if (isActive) ...[
                      const SizedBox(width: 3),
                      TalkTimer(
                        isActive: true,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: isRx
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                        ),
                      ),
                    ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
