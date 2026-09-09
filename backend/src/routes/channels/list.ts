import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { listChannels } from '../../services/channel.service';

export async function listRoute(fastify: FastifyInstance) {
  fastify.get('/', { preHandler: [authenticate] }, async (request) => {
    const channels = await listChannels(request.user.sub);
    return { channels };
  });
}
