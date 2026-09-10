import 'package:flutter/material.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(channelsProvider.notifier).fetchChannels());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, size: 11, color: Color(0xFF4A9EFF)),
                  const SizedBox(width: 4),
                  Text(
                    'Channel Privat',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
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
              const SizedBox(height: 7),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: Color(0xFF2A4A6A),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF060910),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 5),
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
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A6A8A),
                        side:
                            const BorderSide(color: Color(0xFF1E2A3A)),
                        padding: const EdgeInsets.symmetric(vertical: 5),
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
                  const SizedBox(width: 5),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4ADE80),
                        backgroundColor: const Color(0xFF0F1E2E),
                        side:
                            const BorderSide(color: Color(0xFF1E5A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 5),
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

    final filtered = state.channels.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF060C18),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back,
                            size: 11, color: Color(0xFF4A9EFF)),
                        SizedBox(width: 3),
                        Text(
                          'KEMBALI',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 7,
                            color: Color(0xFF4A9EFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'DAFTAR CHANNEL',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: Color(0xFF4A9EFF),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF060910),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF1E2A3A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 10, color: Color(0xFF4A6A8A)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        color: Color(0xFFDBE4F0),
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Cari channel...',
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: Color(0xFF2A4A6A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Channel list
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF4A9EFF),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final channel = filtered[index];
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
    );
  }
}

class _ChannelItem extends StatelessWidget {
  final Channel channel;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ChannelItem({
    required this.channel,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF0A1628) : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF0A1020)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cell_tower,
              size: 13,
              color: isCurrent
                  ? const Color(0xFF4A9EFF)
                  : const Color(0xFF1E4A8A),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
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
                      if (channel.isPrivate) ...[
                        const SizedBox(width: 3),
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
                  '${channel.memberCount}',
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
                    fontSize: 6.5,
                    color: Color(0xFF2A4A6A),
                  ),
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
          fontSize: 6.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
