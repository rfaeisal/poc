import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { rotateRefreshToken } from '../../services/auth.service';

const refreshSchema = z.object({
  refreshToken: z.string(),
});

export async function refreshRoute(fastify: FastifyInstance) {
  fastify.post('/refresh', async (request, reply) => {
    const { refreshToken } = refreshSchema.parse(request.body);
    const result = await rotateRefreshToken(refreshToken);

    if (!result) {
      reply.code(401).send({ error: 'Invalid or expired refresh token' });
      return;
    }

    const accessToken = fastify.jwt.sign({
      sub: result.user.id,
      role: result.user.role,
    });

    reply.send({
      accessToken,
      refreshToken: result.refreshToken,
    });
  });
}
