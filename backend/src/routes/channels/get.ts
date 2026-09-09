import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { getChannel } from '../../services/channel.service';

export async function getRoute(fastify: FastifyInstance) {
  fastify.get<{ Params: { id: string } }>('/:id', { preHandler: [authenticate] }, async (request, reply) => {
    const channel = await getChannel(request.params.id);
    if (!channel) {
      reply.code(404).send({ error: 'Channel not found' });
      return;
    }
    return { channel };
  });
}
