import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';
import { prisma } from '../../lib/prisma';
import { deleteRoom } from '../../services/livekit.service';

export async function channelsRoute(fastify: FastifyInstance) {
  fastify.delete<{ Params: { id: string } }>(
    '/channels/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (!channel) {
        reply.code(404).send({ error: 'Channel not found' });
        return;
      }

      try {
        await deleteRoom(channel.livekitRoomId);
      } catch {
        // Room might not exist
      }

      await prisma.channel.delete({ where: { id: request.params.id } });
      reply.send({ success: true });
    }
  );
}
