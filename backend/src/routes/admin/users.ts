import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';
import { prisma } from '../../lib/prisma';

const banSchema = z.object({
  reason: z.string().min(1).max(500),
});

export async function usersRoute(fastify: FastifyInstance) {
  fastify.get('/users', { preHandler: [authenticate, authorize('ADMIN')] }, async (request) => {
    const query = request.query as { page?: string; limit?: string; q?: string };
    const page = Math.max(1, parseInt(query.page ?? '1'));
    const limit = Math.min(100, Math.max(1, parseInt(query.limit ?? '20')));

    const where = query.q
      ? {
          OR: [
            { email: { contains: query.q, mode: 'insensitive' as const } },
            { profile: { callsign: { contains: query.q, mode: 'insensitive' as const } } },
          ],
        }
      : {};

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: { profile: true },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.user.count({ where }),
    ]);

    return {
      users: users.map((u) => ({
        id: u.id,
        email: u.email,
        role: u.role,
        isActive: u.isActive,
        isBanned: u.isBanned,
        bannedReason: u.bannedReason,
        createdAt: u.createdAt,
        lastSeenAt: u.lastSeenAt,
        profile: u.profile,
      })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  });

  fastify.post<{ Params: { id: string } }>(
    '/users/:id/ban',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      const { reason } = banSchema.parse(request.body);
      await prisma.user.update({
        where: { id: request.params.id },
        data: { isBanned: true, bannedReason: reason },
      });
      reply.send({ success: true });
    }
  );

  fastify.post<{ Params: { id: string } }>(
    '/users/:id/unban',
    { preHandler: [authenticate, authorize('ADMIN')] },
    async (request, reply) => {
      await prisma.user.update({
        where: { id: request.params.id },
        data: { isBanned: false, bannedReason: null },
      });
      reply.send({ success: true });
    }
  );
}
