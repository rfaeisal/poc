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
              const Text(
                'CHANNEL',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF4A6A8A),
                  letterSpacing: 0.5,
                ),
              ),
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
                      '☰ CH LIST',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF4A9EFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            widget.channelName,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: 'AKTIF : ',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
              children: [
                TextSpan(
                  text: '${widget.memberCount} Personel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: List.generate(
              widget.totalChannels.clamp(1, 5),
              (i) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == widget.channelIndex
                        ? const Color(0xFF1E5A9A)
                        : const Color(0xFF0F2040),
                    border: Border.all(
                      color: i == widget.channelIndex
                          ? const Color(0xFF4A9EFF)
                          : const Color(0xFF1E3A5F),
                      width: 1,
                    ),
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
