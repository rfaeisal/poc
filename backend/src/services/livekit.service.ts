import { AccessToken } from 'livekit-server-sdk';
import { config } from '../config';
import { roomService } from '../lib/livekit';

export async function generateChannelToken(
  userId: string,
  callsign: string,
  channelId: string,
  roomName: string,
  role: 'member' | 'moderator' | 'admin'
): Promise<string> {
  const at = new AccessToken(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET, {
    identity: userId,
    name: callsign,
    ttl: '4h',
    metadata: JSON.stringify({ callsign, channelId, role }),
  });

  at.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
    roomAdmin: role === 'admin',
    roomRecord: role === 'admin',
  });

  return await at.toJwt();
}

export async function listRooms() {
  return roomService.listRooms();
}

export async function deleteRoom(roomName: string) {
  await roomService.deleteRoom(roomName);
}

export async function listParticipants(roomName: string) {
  return roomService.listParticipants(roomName);
}

export async function removeParticipant(roomName: string, identity: string) {
  await roomService.removeParticipant(roomName, identity);
}

export async function muteParticipant(roomName: string, identity: string, trackSid: string) {
  await roomService.mutePublishedTrack(roomName, identity, trackSid, true);
}
