import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/services/foreground_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../channels/models/channel.dart';
import '../../channels/models/channel_member.dart';
import '../../channels/providers/channel_members_provider.dart';
import '../../channels/providers/channels_provider.dart';
import '../../map/providers/location_provider.dart';
import '../../ptt/providers/ptt_provider.dart';
import '../../ptt/widgets/ptt_button.dart';
import '../../ptt/widgets/ptt_indicator.dart';
import '../../settings/providers/settings_provider.dart';

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final String channelId;
  final JoinChannelResult? joinResult;

  const ChannelDetailScreen({
    super.key,
    required this.channelId,
    this.joinResult,
  });

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    if (widget.joinResult != null) {
      Future.microtask(() => _connectAll());
    }
  }

  Future<void> _connectAll() async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? '';
    final callsign = auth.user?.profile.callsign ?? '';
    final channelName =
        widget.joinResult?.channel.name ?? 'Channel';

    await ref.read(channelMembersProvider.notifier).joinChannel(
          widget.channelId,
          myUserId: userId,
        );

    await ref.read(pttProvider.notifier).connect(
          widget.joinResult!,
          userId: userId,
          callsign: callsign,
        );

    PttForegroundService.start(channelName);

    // Start location sharing if enabled in settings
    final settings = ref.read(settingsProvider);
    if (settings.locationSharing) {
      ref.read(locationProvider.notifier).startSharing(
            userId: userId,
            callsign: callsign,
            channelId: widget.channelId,
          );
    }
  }

  Future<void> _leaveChannel() async {
    await ref.read(pttProvider.notifier).disconnect();
    await ref.read(channelMembersProvider.notifier).leaveChannel();
    await ref
        .read(channelsProvider.notifier)
        .leaveChannel(widget.channelId);
    await ref.read(locationProvider.notifier).stopSharing();
    PttForegroundService.stop();
    WakelockPlus.disable();
    if (mounted) context.go('/channels');
  }

  @override
  Widget build(BuildContext context) {
    final ptt = ref.watch(pttProvider);
    final membersState = ref.watch(channelMembersProvider);
    final settings = ref.watch(settingsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveChannel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveChannel,
          ),
          title: Text(ptt.channelName ?? 'Channel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () =>
                  context.push('/channels/${widget.channelId}/map'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (settings.voxEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'VOX Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const PttIndicator(),
              const SizedBox(height: 24),
              Expanded(
                child: _MemberGrid(
                  members: membersState.onlineMembers,
                  transmitterId: membersState.transmitterId,
                ),
              ),
              if (ptt.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    ptt.error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: PttButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberGrid extends StatelessWidget {
  final List<ChannelMember> members;
  final String? transmitterId;

  const _MemberGrid({required this.members, this.transmitterId});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Text(
          'Belum ada peserta lain',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members Online (${members.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isTransmitting = member.userId == transmitterId;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isTransmitting
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          child: Text(
                            member.callsign.length >= 2
                                ? member.callsign.substring(0, 2)
                                : member.callsign,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isTransmitting
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isTransmitting
                                  ? Colors.red
                                  : Colors.green,
                              border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.callsign,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isTransmitting
                                ? FontWeight.bold
                                : null,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (member.name != null)
                      Text(
                        member.name!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
