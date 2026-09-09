import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';
import { prisma } from '../../lib/prisma';

export async function statsRoute(fastify: FastifyInstance) {
  fastify.get('/stats', { preHandler: [authenticate, authorize('ADMIN')] }, async () => {
    const [totalUsers, activeUsers, totalChannels, activeChannels, totalOrganizations] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { isActive: true, isBanned: false } }),
      prisma.channel.count(),
      prisma.channel.count({ where: { isActive: true } }),
      prisma.organization.count(),
    ]);

    return {
      stats: {
        totalUsers,
        activeUsers,
        totalChannels,
        activeChannels,
        totalOrganizations,
      },
    };
  });
}
