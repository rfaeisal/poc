import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';

const searchQuerySchema = z.object({
  q: z.string().min(1).max(50),
});

export async function searchRoute(fastify: FastifyInstance) {
  fastify.get('/search', { preHandler: [authenticate] }, async (request) => {
    const { q } = searchQuerySchema.parse(request.query);

    const profiles = await prisma.userProfile.findMany({
      where: {
        OR: [
          { callsign: { contains: q.toUpperCase(), mode: 'insensitive' } },
          { name: { contains: q, mode: 'insensitive' } },
        ],
      },
      take: 20,
    });

    return { users: profiles };
  });
}
