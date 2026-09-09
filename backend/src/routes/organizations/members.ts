import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';

const addMemberSchema = z.object({
  userId: z.string().uuid(),
  role: z.enum(['MEMBER', 'MANAGER']).default('MEMBER'),
});

export async function membersRoute(fastify: FastifyInstance) {
  fastify.get<{ Params: { id: string } }>('/:id/members', { preHandler: [authenticate] }, async (request) => {
    const members = await prisma.organizationMember.findMany({
      where: { organizationId: request.params.id },
      include: { user: { include: { profile: true } } },
    });
    return { members };
  });

  fastify.post<{ Params: { id: string } }>('/:id/members', { preHandler: [authenticate] }, async (request, reply) => {
    const actor = await prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: request.params.id, userId: request.user.sub } },
    });

    if (!actor || (actor.role !== 'OWNER' && actor.role !== 'MANAGER')) {
      reply.code(403).send({ error: 'Insufficient permissions' });
      return;
    }

    const body = addMemberSchema.parse(request.body);

    try {
      const member = await prisma.organizationMember.create({
        data: {
          organizationId: request.params.id,
          userId: body.userId,
          role: body.role,
        },
      });
      reply.code(201).send({ member });
    } catch (err: any) {
      if (err.code === 'P2002') {
        reply.code(409).send({ error: 'User is already a member' });
        return;
      }
      throw err;
    }
  });

  fastify.delete<{ Params: { id: string; userId: string } }>(
    '/:id/members/:userId',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const actor = await prisma.organizationMember.findUnique({
        where: { organizationId_userId: { organizationId: request.params.id, userId: request.user.sub } },
      });

      if (!actor || actor.role !== 'OWNER') {
        reply.code(403).send({ error: 'Only owner can remove members' });
        return;
      }

      await prisma.organizationMember.deleteMany({
        where: { organizationId: request.params.id, userId: request.params.userId },
      });

      reply.send({ success: true });
    }
  );
}
