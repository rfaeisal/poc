import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';
import { changePassword } from '../../services/auth.service';

const updateProfileSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  bio: z.string().max(500).optional(),
  photoUrl: z.string().url().optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string(),
  newPassword: z.string().min(8),
});

export async function meRoute(fastify: FastifyInstance) {
  fastify.get('/me', { preHandler: [authenticate] }, async (request) => {
    const user = await prisma.user.findUnique({
      where: { id: request.user.sub },
      include: { profile: true },
    });
    return {
      user: {
        id: user!.id,
        email: user!.email,
        role: user!.role,
        profile: user!.profile,
      },
    };
  });

  fastify.patch('/me', { preHandler: [authenticate] }, async (request) => {
    const body = updateProfileSchema.parse(request.body);
    const profile = await prisma.userProfile.update({
      where: { userId: request.user.sub },
      data: body,
    });
    return { profile };
  });

  fastify.post('/change-password', { preHandler: [authenticate] }, async (request, reply) => {
    const { currentPassword, newPassword } = changePasswordSchema.parse(request.body);
    const success = await changePassword(request.user.sub, currentPassword, newPassword);

    if (!success) {
      reply.code(400).send({ error: 'Current password is incorrect' });
      return;
    }

    reply.send({ success: true });
  });
}
