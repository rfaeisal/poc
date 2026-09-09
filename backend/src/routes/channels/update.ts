import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';

const updateSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  description: z.string().max(500).optional(),
  maxMembers: z.number().min(2).max(500).optional(),
  isActive: z.boolean().optional(),
});

export async function updateRoute(fastify: FastifyInstance) {
  fastify.patch<{ Params: { id: string } }>('/:id', { preHandler: [authenticate] }, async (request, reply) => {
    const member = await prisma.channelMember.findUnique({
      where: { channelId_userId: { channelId: request.params.id, userId: request.user.sub } },
    });

    if (!member || member.role !== 'ADMIN') {
      reply.code(403).send({ error: 'Only channel admin can update' });
      return;
    }

    const body = updateSchema.parse(request.body);
    const channel = await prisma.channel.update({
      where: { id: request.params.id },
      data: body,
    });

    return { channel };
  });
}
