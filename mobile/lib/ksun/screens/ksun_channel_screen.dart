import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/foreground_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/channels/models/channel.dart';
import '../../features/channels/providers/channel_members_provider.dart';
import '../../features/channels/providers/channels_provider.dart';
import '../../features/map/providers/location_provider.dart';
import '../../features/ptt/providers/ptt_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../services/ksun_kiosk_service.dart';
import '../widgets/ksun_audio_spectrograph.dart';
import '../widgets/ksun_channel_frame.dart';
import '../widgets/ksun_speaker_box.dart';
import '../widgets/ksun_status_bar.dart';

class KsunChannelScreen extends ConsumerStatefulWidget {
  const KsunChannelScreen({super.key});

  @override
  ConsumerState<KsunChannelScreen> createState() =>
      _KsunChannelScreenState();
}

class _KsunChannelScreenState extends ConsumerState<KsunChannelScreen> {
  JoinChannelResult? _joinResult;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _autoJoin());
  }

  Future<void> _autoJoin() async {
    final ptt = ref.read(pttProvider);
    if (ptt.channelName != null) return;

    setState(() => _connecting = true);
    try {
      await ref.read(channelsProvider.notifier).fetchChannels();
      final channels = ref.read(channelsProvider).channels;
      if (channels.isEmpty || !mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('ksun_last_channel');
      final target = channels.firstWhere(
        (c) => c.id == lastId,
        orElse: () => channels.first,
      );

      final result = await ref
          .read(channelsProvider.notifier)
          .joinChannel(target.id);

      if (!mounted || result == null) return;

      await prefs.setString('ksun_last_channel', target.id);
      _joinResult = result;
      await _connectAll(result);
    } catch (_) {}
    if (mounted) setState(() => _connecting = false);
  }

  Future<void> _connectAll(JoinChannelResult joinResult) async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? '';
    final callsign = auth.user?.profile.callsign ?? '';
    final channelName = joinResult.channel.name;

    await ref.read(channelMembersProvider.notifier).joinChannel(
          joinResult.channel.id,
          myUserId: userId,
        );

    await ref.read(pttProvider.notifier).connect(
          joinResult,
          userId: userId,
          callsign: callsign,
        );

    PttForegroundService.start(channelName);
    KsunKioskService.keepScreenOn();

    final settings = ref.read(settingsProvider);
    if (settings.locationSharing) {
      ref.read(locationProvider.notifier).startSharing(
            userId: userId,
            callsign: callsign,
            channelId: joinResult.channel.id,
          );
    }
  }

  Future<void> _switchChannel(JoinChannelResult newResult) async {
    await ref.read(pttProvider.notifier).disconnect();
    await ref.read(channelMembersProvider.notifier).leaveChannel();
    await ref.read(locationProvider.notifier).stopSharing();

    _joinResult = newResult;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ksun_last_channel', newResult.channel.id);
    await _connectAll(newResult);
    if (mounted) setState(() {});
  }

  int _currentChannelIndex() {
    final channels = ref.read(channelsProvider).channels;
    final currentId = _joinResult?.channel.id;
    final idx = channels.indexWhere((c) => c.id == currentId);
    return idx < 0 ? 0 : idx;
  }

  void _openChannelList() async {
    final result = await context.push<JoinChannelResult>('/channel-list');
    if (result != null && mounted) {
      await _switchChannel(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ptt = ref.watch(pttProvider);
    final membersState = ref.watch(channelMembersProvider);

    if (_connecting) {
      return const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFF4A9EFF),
          ),
        ),
      );
    }

    final isTransmitting = ptt.isTransmitting;
    final isReceiving =
        !ptt.isTransmitting && ptt.currentSpeakerCallsign != null;

    return Column(
      children: [
        KsunStatusBar(
          isMqttConnected: ref.watch(mqttConnectedProvider).valueOrNull ?? false,
        ),
        const KsunSpeakerBox(),
        KsunAudioSpectrograph(
          isTransmitting: isTransmitting,
          isReceiving: isReceiving,
        ),
        KsunChannelFrame(
          channelName: ptt.channelName ?? 'No Channel',
          memberCount: membersState.onlineMembers.length,
          channelIndex: _currentChannelIndex(),
          totalChannels: ref.read(channelsProvider).channels.length,
          connectionStatus: ptt.connectionStatus,
          onChannelListTap: _openChannelList,
        ),
      ],
    );
  }
}
