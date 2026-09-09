import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';

export async function profileRoute(fastify: FastifyInstance) {
  fastify.get<{ Params: { id: string } }>('/:id/profile', { preHandler: [authenticate] }, async (request, reply) => {
    const profile = await prisma.userProfile.findFirst({
      where: { userId: request.params.id },
    });

    if (!profile) {
      reply.code(404).send({ error: 'Profile not found' });
      return;
    }

    return { profile };
  });
}
