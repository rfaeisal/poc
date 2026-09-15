import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/channels/models/channel.dart';
import '../../features/channels/providers/channels_provider.dart';
import '../../features/ptt/providers/ptt_provider.dart';

class KsunChannelListScreen extends ConsumerStatefulWidget {
  const KsunChannelListScreen({super.key});

  @override
  ConsumerState<KsunChannelListScreen> createState() =>
      _KsunChannelListScreenState();
}

class _KsunChannelListScreenState
    extends ConsumerState<KsunChannelListScreen> {
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
    var result = await ref
        .read(channelsProvider.notifier)
        .joinChannel(channel.id);

    if (!mounted) return;

    if (result == null && channel.isPrivate) {
      final error = ref.read(channelsProvider).error;
      if (error != null && error.contains('Password required')) {
        final password = await _showPasswordDialog(channel);
        if (password == null) return;
        result = await ref
            .read(channelsProvider.notifier)
            .joinChannel(channel.id, password: password);
        if (!mounted) return;
      }
    }

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
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, size: 8, color: Color(0xFF4A9EFF)),
                  const SizedBox(width: 3),
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
              const SizedBox(height: 2),
              Text(
                channel.name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: Color(0xFF4A6A8A),
                ),
              ),
              const SizedBox(height: 4),
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
                    fontSize: 7,
                    color: Color(0xFF2A4A6A),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF060910),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E2A3A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide:
                        const BorderSide(color: Color(0xFF1E2A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide:
                        const BorderSide(color: Color(0xFF4A9EFF)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A6A8A),
                        side:
                            const BorderSide(color: Color(0xFF1E2A3A)),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: const Text(
                        'BATAL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4ADE80),
                        backgroundColor: const Color(0xFF0F1E2E),
                        side:
                            const BorderSide(color: Color(0xFF1E5A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: const Text(
                        'JOIN',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 7,
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
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'CHANNEL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: Color(0xFF4A9EFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(channelsProvider.notifier).fetchChannels(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1E2E),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFF1E3A5F)),
                        ),
                        child: const Text(
                          'REFRESH',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A9EFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: _focused
                ? const Color(0xFF0F1E2E)
                : widget.isCurrent
                    ? const Color(0xFF0A1628)
                    : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cell_tower,
                size: 9,
                color: _focused || widget.isCurrent
                    ? const Color(0xFF4A9EFF)
                    : const Color(0xFF1E4A8A),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: _focused || widget.isCurrent
                            ? const Color(0xFF4A9EFF)
                            : const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (widget.channel.isPrivate)
                          _Badge(
                            text: 'PVT',
                            bgColor: const Color(0xFF1A1A08),
                            textColor: const Color(0xFFA07A10),
                            borderColor: const Color(0xFF3A3008),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.channel.memberCount}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A6A8A),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(1),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
