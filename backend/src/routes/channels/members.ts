import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { getChannelMembers, muteMember, kickMember } from '../../services/channel.service';
import { removeParticipant } from '../../services/livekit.service';
import { prisma } from '../../lib/prisma';

export async function membersRoute(fastify: FastifyInstance) {
  fastify.get<{ Params: { id: string } }>('/:id/members', { preHandler: [authenticate] }, async (request) => {
    const members = await getChannelMembers(request.params.id);
    return { members };
  });

  fastify.post<{ Params: { id: string; userId: string } }>(
    '/:id/members/:userId/mute',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const actor = await prisma.channelMember.findUnique({
        where: { channelId_userId: { channelId: request.params.id, userId: request.user.sub } },
      });

      if (!actor || (actor.role !== 'ADMIN' && actor.role !== 'MODERATOR')) {
        reply.code(403).send({ error: 'Insufficient permissions' });
        return;
      }

      await muteMember(request.params.id, request.params.userId, true);
      reply.send({ success: true });
    }
  );

  fastify.post<{ Params: { id: string; userId: string } }>(
    '/:id/members/:userId/kick',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const actor = await prisma.channelMember.findUnique({
        where: { channelId_userId: { channelId: request.params.id, userId: request.user.sub } },
      });

      if (!actor || (actor.role !== 'ADMIN' && actor.role !== 'MODERATOR')) {
        reply.code(403).send({ error: 'Insufficient permissions' });
        return;
      }

      const channel = await prisma.channel.findUnique({ where: { id: request.params.id } });
      if (channel) {
        try {
          await removeParticipant(channel.livekitRoomId, request.params.userId);
        } catch {
          // Participant might not be in the room
        }
      }

      await kickMember(request.params.id, request.params.userId);
      reply.send({ success: true });
    }
  );
}
