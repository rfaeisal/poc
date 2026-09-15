import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/ptt/providers/ptt_provider.dart';

class KsunChannelFrame extends StatefulWidget {
  final String channelName;
  final int memberCount;
  final int channelIndex;
  final int totalChannels;
  final ConnectionStatus connectionStatus;
  final VoidCallback? onChannelListTap;

  const KsunChannelFrame({
    super.key,
    required this.channelName,
    required this.memberCount,
    this.channelIndex = 0,
    this.totalChannels = 1,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.onChannelListTap,
  });

  @override
  State<KsunChannelFrame> createState() => _KsunChannelFrameState();
}

class _KsunChannelFrameState extends State<KsunChannelFrame> {
  bool _buttonFocused = false;

  @override
  Widget build(BuildContext context) {
    final connColor = widget.connectionStatus == ConnectionStatus.connected
        ? const Color(0xFF4ADE80)
        : widget.connectionStatus == ConnectionStatus.connecting
            ? const Color(0xFFFBBF24)
            : const Color(0xFFEF4444);
    final connText = widget.connectionStatus == ConnectionStatus.connected
        ? 'OK'
        : widget.connectionStatus == ConnectionStatus.connecting
            ? '..'
            : 'X';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: const BoxDecoration(
        color: Color(0xFF060C18),
        border: Border(
          top: BorderSide(color: Color(0xFF0F1E2E), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connColor,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            connText,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              color: connColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.channelName,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: Color(0xFFE2E8F0),
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.totalChannels > 1) ...[
            Text(
              '${widget.channelIndex + 1}/${widget.totalChannels}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
                color: Color(0xFF4A6A8A),
              ),
            ),
            const SizedBox(width: 3),
          ],
          Focus(
            onFocusChange: (f) => setState(() => _buttonFocused = f),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  widget.onChannelListTap != null &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey ==
                          LogicalKeyboardKey.gameButtonA)) {
                widget.onChannelListTap!();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: widget.onChannelListTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: _buttonFocused
                      ? const Color(0xFF1A3A5F)
                      : const Color(0xFF0F1E2E),
                  border: Border.all(
                    color: _buttonFocused
                        ? const Color(0xFF4A9EFF)
                        : const Color(0xFF1E3A5F),
                    width: _buttonFocused ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'CH▼',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    color: Color(0xFF4A9EFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
