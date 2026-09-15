import {
  Room,
  RoomEvent,
  AudioStream,
  AudioSource,
  AudioFrame,
  LocalAudioTrack,
  RemoteTrackPublication,
  RemoteParticipant,
  TrackKind,
  TrackPublishOptions,
  TrackSource,
} from '@livekit/rtc-node';
import { AccessToken } from 'livekit-server-sdk';
import { config } from '../config';

const SAMPLE_RATE = 48000;
const NUM_CHANNELS = 1;
const BOT_CALLSIGN = 'RS83CHO';
const BOT_NAME = 'Nom Echo BOT';

interface EchoBotSession {
  room: Room;
  cleanup: () => Promise<void>;
}

const activeSessions = new Map<string, EchoBotSession>();

async function generateBotToken(roomName: string, userId: string): Promise<string> {
  const token = new AccessToken(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET, {
    identity: `echo-bot-${userId}`,
    name: BOT_NAME,
    ttl: '10m',
    metadata: JSON.stringify({ callsign: BOT_CALLSIGN, isBot: true }),
  });
  token.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
  });
  return await token.toJwt();
}

export async function startEchoBot(roomName: string, userId: string): Promise<void> {
  await stopEchoBot(userId);

  const botToken = await generateBotToken(roomName, userId);
  const room = new Room();

  let audioBuffer: AudioFrame[] = [];
  let isBuffering = false;

  room.on(RoomEvent.TrackSubscribed, async (track, publication: RemoteTrackPublication, participant: RemoteParticipant) => {
    if (track.kind !== TrackKind.KIND_AUDIO) return;
    if (participant.identity === `echo-bot-${userId}`) return;

    isBuffering = true;
    audioBuffer = [];

    const stream = new AudioStream(track, SAMPLE_RATE, NUM_CHANNELS);
    const reader = stream.getReader();
    let logged = false;

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done || !isBuffering) break;
        if (!logged) {
          console.log(`[EchoBot] RX frame: ${value.sampleRate}Hz, ${value.channels}ch, ${value.samplesPerChannel}spc, data=${value.data.length}`);
          logged = true;
        }
        audioBuffer.push(value);
      }
    } catch {
      // stream ended
    } finally {
      reader.releaseLock();
    }
  });

  room.on(RoomEvent.TrackUnsubscribed, async (_track, _publication: RemoteTrackPublication, participant: RemoteParticipant) => {
    if (participant.identity === `echo-bot-${userId}`) return;
    if (!isBuffering) return;

    isBuffering = false;
    const frames = [...audioBuffer];
    audioBuffer = [];

    if (frames.length === 0) return;

    try {
      const firstFrame = frames[0];
      const srcRate = firstFrame.sampleRate || SAMPLE_RATE;
      const srcChannels = firstFrame.channels || NUM_CHANNELS;
      console.log(`[EchoBot] Playback: ${frames.length} frames, ${srcRate}Hz, ${srcChannels}ch`);
      const source = new AudioSource(srcRate, srcChannels);
      const localTrack = LocalAudioTrack.createAudioTrack('echo-playback', source);
      const pubOptions = new TrackPublishOptions({ source: TrackSource.SOURCE_MICROPHONE });
      const publication = await room.localParticipant!.publishTrack(localTrack, pubOptions);

      for (const frame of frames) {
        await source.captureFrame(frame);
      }
      await source.waitForPlayout();

      await room.localParticipant!.unpublishTrack(publication.sid!);
      await localTrack.close();
    } catch (e) {
      console.error(`[EchoBot] Failed to publish echo for ${userId}:`, e);
    }
  });

  await room.connect(config.LIVEKIT_URL, botToken, { autoSubscribe: true, dynacast: false });

  const session: EchoBotSession = {
    room,
    cleanup: async () => {
      isBuffering = false;
      audioBuffer = [];
      try {
        await room.disconnect();
      } catch {}
    },
  };

  activeSessions.set(userId, session);
}

export async function stopEchoBot(userId: string): Promise<void> {
  const session = activeSessions.get(userId);
  if (session) {
    await session.cleanup();
    activeSessions.delete(userId);
  }
}

export function isEchoBotActive(userId: string): boolean {
  return activeSessions.has(userId);
}
