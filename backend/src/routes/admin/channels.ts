import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';
import { prisma } from '../../lib/prisma';
import { deleteRoom } from '../../services/livekit.service';

const updateSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  description: z.string().max(500).optional(),
  maxMembers: z.number().min(2).max(500).optional(),
  isActive: z.boolean().optional(),
  isPrivate: z.boolean().optional(),
});

export async function channelsRoute(fastify: FastifyInstance) {
  // Admin update channel (bypasses membership check)
  fastify.patch<{ Params: { id: string } }>(
    '/channels/:id',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (!channel) {
        reply.code(404).send({ error: 'Channel not found' });
        return;
      }

      const body = updateSchema.parse(request.body);
      const updated = await prisma.channel.update({
        where: { id: request.params.id },
        data: body,
        include: {
          _count: { select: { members: true } },
          members: {
            include: { user: { include: { profile: true } } },
          },
        },
      });

      return { channel: updated };
    }
  );

  // Admin delete channel
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
