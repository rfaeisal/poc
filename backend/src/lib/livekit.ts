import { RoomServiceClient } from 'livekit-server-sdk';
import { config } from '../config';

export const roomService = new RoomServiceClient(
  config.LIVEKIT_URL,
  config.LIVEKIT_API_KEY,
  config.LIVEKIT_API_SECRET
);
