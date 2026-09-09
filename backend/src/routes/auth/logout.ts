import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { revokeRefreshToken } from '../../services/auth.service';

const logoutSchema = z.object({
  refreshToken: z.string(),
});

export async function logoutRoute(fastify: FastifyInstance) {
  fastify.post('/logout', { preHandler: [authenticate] }, async (request, reply) => {
    const { refreshToken } = logoutSchema.parse(request.body);
    await revokeRefreshToken(refreshToken);
    reply.send({ success: true });
  });
}
