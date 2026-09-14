import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HyteraChannelFrame extends StatefulWidget {
  final String channelName;
  final int memberCount;
  final int channelIndex;
  final int totalChannels;
  final VoidCallback? onChannelListTap;

  const HyteraChannelFrame({
    super.key,
    required this.channelName,
    required this.memberCount,
    this.channelIndex = 0,
    this.totalChannels = 1,
    this.onChannelListTap,
  });

  @override
  State<HyteraChannelFrame> createState() => _HyteraChannelFrameState();
}

class _HyteraChannelFrameState extends State<HyteraChannelFrame> {
  bool _buttonFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF060C18),
        border: Border(
          top: BorderSide(color: Color(0xFF0F1E2E), width: 1),
          bottom: BorderSide(color: Color(0xFF0F1E2E), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.channelName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
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
                        horizontal: 6, vertical: 2),
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
                      borderRadius: BorderRadius.circular(3),
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
          Row(
            children: [
              Text(
                '${widget.memberCount} online',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: Color(0xFF64748B),
                ),
              ),
              if (widget.totalChannels > 1) ...[
                const Spacer(),
                Text(
                  'CH ${widget.channelIndex + 1}/${widget.totalChannels}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 6,
                    color: Color(0xFF4A6A8A),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
