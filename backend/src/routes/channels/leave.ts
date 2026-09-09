import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/authenticate';
import { leaveChannel } from '../../services/channel.service';
import { publishMemberEvent } from '../../services/mqtt.service';
import { prisma } from '../../lib/prisma';

export async function leaveRoute(fastify: FastifyInstance) {
  fastify.post<{ Params: { id: string } }>('/:id/leave', { preHandler: [authenticate] }, async (request, reply) => {
    const profile = await prisma.userProfile.findUnique({
      where: { userId: request.user.sub },
    });

    await leaveChannel(request.params.id, request.user.sub);
    publishMemberEvent(request.params.id, request.user.sub, profile?.callsign ?? 'unknown', 'leave');

    reply.send({ success: true });
  });
}
