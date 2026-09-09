import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { registerUser, createRefreshToken } from '../../services/auth.service';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  callsign: z.string().min(3).max(20).regex(/^[A-Za-z0-9]+$/),
  name: z.string().min(2).max(100),
});

export async function registerRoute(fastify: FastifyInstance) {
  fastify.post('/register', async (request, reply) => {
    const body = registerSchema.parse(request.body);

    try {
      const user = await registerUser(body);
      const accessToken = fastify.jwt.sign({ sub: user.id, role: user.role });
      const refreshToken = await createRefreshToken(user.id);

      reply.code(201).send({
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          profile: user.profile,
        },
        accessToken,
        refreshToken,
      });
    } catch (err: any) {
      if (err.code === 'P2002') {
        const field = err.meta?.target?.[0] ?? 'field';
        reply.code(409).send({ error: `${field} already exists` });
        return;
      }
      throw err;
    }
  });
}
