import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';
import { deleteRoom } from '../../services/livekit.service';

export async function deleteRoute(fastify: FastifyInstance) {
  fastify.delete<{ Params: { id: string } }>('/:id', { preHandler: [authenticate] }, async (request, reply) => {
    const member = await prisma.channelMember.findUnique({
      where: { channelId_userId: { channelId: request.params.id, userId: request.user.sub } },
    });

    if (!member || member.role !== 'ADMIN') {
      reply.code(403).send({ error: 'Only channel admin can delete' });
      return;
    }

    const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
    if (!channel) {
      reply.code(404).send({ error: 'Channel not found' });
      return;
    }

    try {
      await deleteRoom(channel.livekitRoomId);
    } catch {
      // Room might not exist in LiveKit
    }

    await prisma.channel.delete({ where: { id: request.params.id } });
    reply.send({ success: true });
  });
}
