import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';

const createOrgSchema = z.object({
  name: z.string().min(2).max(100),
  slug: z.string().min(2).max(50).regex(/^[a-z0-9-]+$/),
});

export async function createRoute(fastify: FastifyInstance) {
  fastify.post('/', { preHandler: [authenticate] }, async (request, reply) => {
    const body = createOrgSchema.parse(request.body);

    try {
      const org = await prisma.organization.create({
        data: {
          ...body,
          users: {
            create: {
              userId: request.user.sub,
              role: 'OWNER',
            },
          },
        },
      });
      reply.code(201).send({ organization: org });
    } catch (err: any) {
      if (err.code === 'P2002') {
        reply.code(409).send({ error: 'Slug already exists' });
        return;
      }
      throw err;
    }
  });

  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [authenticate] }, async (request, reply) => {
    const org = await prisma.organization.findUnique({
      where: { id: request.params.id },
      include: { _count: { select: { users: true, channels: true } } },
    });

    if (!org) {
      reply.code(404).send({ error: 'Organization not found' });
      return;
    }

    return { organization: org };
  });
}
