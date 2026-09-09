import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/channel.dart';
import '../providers/channels_provider.dart';

class ChannelListScreen extends ConsumerStatefulWidget {
  const ChannelListScreen({super.key});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(channelsProvider.notifier).fetchChannels());
  }

  Future<void> _joinChannel(Channel channel) async {
    String? password;

    if (channel.isPrivate) {
      password = await _showPasswordDialog();
      if (password == null) return;
    }

    final result = await ref
        .read(channelsProvider.notifier)
        .joinChannel(channel.id, password: password);

    if (!mounted || result == null) {
      if (mounted) {
        final error = ref.read(channelsProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      }
      return;
    }

    context.go('/channels/${channel.id}/ptt', extra: result);
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Channel Privat'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration:
              const InputDecoration(labelText: 'Password channel'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POC-Pecek'),
        actions: [
          if (auth.user?.profile.callsign != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  auth.user!.profile.callsign!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(channelsProvider.notifier)
                            .fetchChannels(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(channelsProvider.notifier).fetchChannels(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.channels.length,
                    itemBuilder: (context, index) {
                      final channel = state.channels[index];
                      return _ChannelCard(
                        channel: channel,
                        onTap: () => _joinChannel(channel),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: channel.isPrivate
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            channel.isPrivate ? Icons.lock : Icons.radio,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(
          channel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          channel.description ?? 'Channel ${channel.isPrivate ? "privat" : "publik"}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 16),
            const SizedBox(width: 4),
            Text('${channel.memberCount}'),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
