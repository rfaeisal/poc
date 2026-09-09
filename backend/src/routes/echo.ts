import { FastifyInstance } from 'fastify';
import { AccessToken } from 'livekit-server-sdk';
import { authenticate } from '../middleware/authenticate';
import { config } from '../config';
import { roomService } from '../lib/livekit';

export default async function echoRoutes(fastify: FastifyInstance) {
  fastify.post('/echo/start', { preHandler: [authenticate] }, async (request, reply) => {
    const userId = request.user.sub;
    const roomName = `echo-${userId}`;

    try {
      await roomService.deleteRoom(roomName);
    } catch {
      // room doesn't exist yet, fine
    }

    await roomService.createRoom({ name: roomName, emptyTimeout: 300, maxParticipants: 2 });

    const publishToken = new AccessToken(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET, {
      identity: userId,
      name: 'You',
      ttl: '10m',
    });
    publishToken.addGrant({
      room: roomName,
      roomJoin: true,
      canPublish: true,
      canSubscribe: false,
    });

    const subscribeToken = new AccessToken(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET, {
      identity: `echo-${userId}`,
      name: 'Echo Bot',
      ttl: '10m',
    });
    subscribeToken.addGrant({
      room: roomName,
      roomJoin: true,
      canPublish: false,
      canSubscribe: true,
    });

    return {
      room: roomName,
      publishToken: await publishToken.toJwt(),
      subscribeToken: await subscribeToken.toJwt(),
    };
  });

  fastify.post('/echo/stop', { preHandler: [authenticate] }, async (request) => {
    const roomName = `echo-${request.user.sub}`;
    try {
      await roomService.deleteRoom(roomName);
    } catch {
      // already gone
    }
    return { ok: true };
  });
}
