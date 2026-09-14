import { FastifyInstance } from 'fastify';
import { AccessToken } from 'livekit-server-sdk';
import { authenticate } from '../middleware/authenticate';
import { config } from '../config';
import { roomService } from '../lib/livekit';
import { startEchoBot, stopEchoBot } from '../services/echo-bot.service';

export default async function echoRoutes(fastify: FastifyInstance) {
  fastify.post('/echo/start', { preHandler: [authenticate] }, async (request, reply) => {
    const userId = request.user.sub;
    const roomName = `echo-${userId}`;

    try {
      await roomService.deleteRoom(roomName);
    } catch {
      // room doesn't exist yet
    }

    await roomService.createRoom({ name: roomName, emptyTimeout: 300, maxParticipants: 3 });

    const userToken = new AccessToken(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET, {
      identity: userId,
      name: 'You',
      ttl: '10m',
    });
    userToken.addGrant({
      room: roomName,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
    });

    await startEchoBot(roomName, userId);

    return {
      room: roomName,
      token: await userToken.toJwt(),
    };
  });

  fastify.post('/echo/stop', { preHandler: [authenticate] }, async (request) => {
    const userId = request.user.sub;
    const roomName = `echo-${userId}`;

    await stopEchoBot(userId);

    try {
      await roomService.deleteRoom(roomName);
    } catch {
      // already gone
    }
    return { ok: true };
  });
}
