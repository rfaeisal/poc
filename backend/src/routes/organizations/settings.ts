import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../../middleware/authenticate';
import { prisma } from '../../lib/prisma';

const updateSettingsSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  logoUrl: z.string().url().optional(),
  maxUsers: z.number().min(1).optional(),
  maxChannels: z.number().min(1).optional(),
  settings: z.record(z.unknown()).optional(),
});

export async function settingsRoute(fastify: FastifyInstance) {
  fastify.get<{ Params: { id: string } }>('/:id/settings', { preHandler: [authenticate] }, async (request, reply) => {
    const org = await prisma.organization.findUnique({
      where: { id: request.params.id },
    });

    if (!org) {
      reply.code(404).send({ error: 'Organization not found' });
      return;
    }

    return { settings: org };
  });

  fastify.patch<{ Params: { id: string } }>('/:id/settings', { preHandler: [authenticate] }, async (request, reply) => {
    const actor = await prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId: request.params.id, userId: request.user.sub } },
    });

    if (!actor || actor.role !== 'OWNER') {
      reply.code(403).send({ error: 'Only owner can update settings' });
      return;
    }

    const body = updateSettingsSchema.parse(request.body);
    const org = await prisma.organization.update({
      where: { id: request.params.id },
      data: body,
    });

    return { organization: org };
  });
}
