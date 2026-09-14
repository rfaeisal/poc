import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/channels/models/channel.dart';
import '../../features/channels/providers/channels_provider.dart';
import '../../features/ptt/providers/ptt_provider.dart';

class HyteraChannelListScreen extends ConsumerStatefulWidget {
  const HyteraChannelListScreen({super.key});

  @override
  ConsumerState<HyteraChannelListScreen> createState() =>
      _HyteraChannelListScreenState();
}

class _HyteraChannelListScreenState
    extends ConsumerState<HyteraChannelListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(channelsProvider.notifier).fetchChannels());
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.browserBack) {
        if (mounted) context.pop();
        return true;
      }
    }
    return false;
  }

  Future<void> _joinChannel(Channel channel) async {
    String? password;
    if (channel.isPrivate) {
      password = await _showPasswordDialog(channel);
      if (password == null) return;
    }

    final result = await ref
        .read(channelsProvider.notifier)
        .joinChannel(channel.id, password: password);

    if (!mounted) return;
    if (result != null) {
      context.pop(result);
    } else {
      final error = ref.read(channelsProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<String?> _showPasswordDialog(Channel channel) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0D1420),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, size: 14, color: Color(0xFF4A9EFF)),
                  const SizedBox(width: 5),
                  Text(
                    'Channel Privat',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      color: Color(0xFF4A9EFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                channel.name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: Color(0xFF4A6A8A),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    color: Color(0xFF2A4A6A),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF060910),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E2A3A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E2A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Color(0xFF4A9EFF)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A6A8A),
                        side:
                            const BorderSide(color: Color(0xFF1E2A3A)),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'BATAL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4ADE80),
                        backgroundColor: const Color(0xFF0F1E2E),
                        side:
                            const BorderSide(color: Color(0xFF1E5A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'JOIN',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelsProvider);
    final ptt = ref.watch(pttProvider);
    final currentChannelName = ptt.channelName;

    final channels = state.channels;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: const Color(0xFF060C18),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: const Text(
                  'CHANNEL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: Color(0xFF4A9EFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4A9EFF),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final isCurrent =
                              channel.name == currentChannelName;
                          return _ChannelItem(
                            channel: channel,
                            isCurrent: isCurrent,
                            onTap: () => _joinChannel(channel),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelItem extends StatefulWidget {
  final Channel channel;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ChannelItem({
    required this.channel,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<_ChannelItem> createState() => _ChannelItemState();
}

class _ChannelItemState extends State<_ChannelItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: _focused
                ? const Color(0xFF0F1E2E)
                : widget.isCurrent
                    ? const Color(0xFF0A1628)
                    : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cell_tower,
                size: 16,
                color: _focused || widget.isCurrent
                    ? const Color(0xFF4A9EFF)
                    : const Color(0xFF1E4A8A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _focused || widget.isCurrent
                            ? const Color(0xFF4A9EFF)
                            : const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _Badge(
                          text: 'IDLE',
                          bgColor: const Color(0xFF0F1E2E),
                          textColor: const Color(0xFF2A4A6A),
                        ),
                        if (widget.channel.isPrivate) ...[
                          const SizedBox(width: 4),
                          _Badge(
                            text: 'PRIVAT',
                            bgColor: const Color(0xFF1A1A08),
                            textColor: const Color(0xFFA07A10),
                            borderColor: const Color(0xFF3A3008),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.channel.memberCount}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A6A8A),
                    ),
                  ),
                  const Text(
                    'online',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 6,
                      color: Color(0xFF2A4A6A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _Badge({
    required this.text,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(2),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 6,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
