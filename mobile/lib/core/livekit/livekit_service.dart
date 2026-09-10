import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_config.dart';

class LiveKitService {
  Room? _room;
  LocalAudioTrack? _audioTrack;

  Room? get room => _room;
  bool get isConnected => _room?.connectionState == ConnectionState.connected;
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];

  Future<void> connect({
    required String url,
    required String token,
  }) async {
    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(
          encoding: AudioEncoding(maxBitrate: AppConfig.audioBitrate),
          dtx: true,
        ),
        defaultAudioCaptureOptions: AudioCaptureOptions(
          noiseSuppression: true,
          echoCancellation: true,
          autoGainControl: true,
        ),
      ),
    );

    await _room!.connect(url, token);

    await Permission.microphone.request();
  }

  Future<void> startTransmit() async {
    if (_room == null) return;

    _audioTrack = await LocalAudioTrack.create(
      const AudioCaptureOptions(
        noiseSuppression: true,
        echoCancellation: true,
        autoGainControl: true,
      ),
    );

    await _room!.localParticipant?.publishAudioTrack(_audioTrack!);
  }

  Future<void> stopTransmit() async {
    if (_audioTrack != null) {
      final sid = _audioTrack!.sid;
      if (sid != null) {
        await _room?.localParticipant?.removePublishedTrack(sid);
      }
      await _audioTrack?.dispose();
      _audioTrack = null;
    }
  }

  Future<void> disconnect() async {
    await stopTransmit();
    try {
      await _room?.disconnect();
    } catch (_) {}
    await _room?.dispose();
    _room = null;
  }
}
