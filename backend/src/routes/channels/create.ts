import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { createChannel } from '../../services/channel.service';

const createSchema = z.object({
  name: z.string().min(2).max(100),
  description: z.string().max(500).optional(),
  isPrivate: z.boolean().default(false),
  password: z.string().min(4).optional(),
  maxMembers: z.number().min(2).max(500).optional(),
  organizationId: z.string().uuid().optional(),
});

export async function createRoute(fastify: FastifyInstance) {
  fastify.post('/', { preHandler: [authenticate] }, async (request, reply) => {
    const body = createSchema.parse(request.body);
    const channel = await createChannel({
      ...body,
      createdById: request.user.sub,
    });
    reply.code(201).send({ channel });
  });
}
