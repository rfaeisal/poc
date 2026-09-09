import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { verifyPassword, createRefreshToken } from '../../services/auth.service';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export async function loginRoute(fastify: FastifyInstance) {
  fastify.post('/login', async (request, reply) => {
    const { email, password } = loginSchema.parse(request.body);
    const user = await verifyPassword(email, password);

    if (!user) {
      reply.code(401).send({ error: 'Invalid credentials' });
      return;
    }

    const accessToken = fastify.jwt.sign({ sub: user.id, role: user.role });
    const refreshToken = await createRefreshToken(user.id);

    reply.send({
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        profile: user.profile,
      },
      accessToken,
      refreshToken,
    });
  });
}
